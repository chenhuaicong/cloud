# cephfs-provision 对接kubernetns
![image](https://github.com/chenhuaicong/cloud/blob/master/kubernetes-ceph.jpg?raw=true)



- 无需担心将 ceph 的 admin 权限给 K8s，K8s 会自动通过 admin 账户创建独立的新账户给 PV，从而隔离每个账户和 PV 的目录权限；删除 PVC 时也会自动删除账户
- 笔记中创建和使用了 “cephfs” 命名空间，秘钥保存在 “kube-system” 命名空间

## Ceph 操作部分
此节所有操作需要在【Ceph 节点】中进行。

确认 MDS 节点
使用 CephFS 必须保证至少有一个节点提供 mds 服务，可以使用 ceph -s 查看。
若没有 MDS 节点，请创建至少一个。

#### 创建资源池

```
ceph osd pool create cephfs_data 128
ceph osd pool create cephfs_metadata 128
```

文件系统需要两个资源池，一个用于存储数据本体，一个用于存放索引信息及其他数据相关信息。

#### 创建文件系统


```
ceph fs new cephfs cephfs_metadata cephfs_data
```
#### 获取 admin 秘钥

```
ceph auth get-key client.admin | base64
```
这里输出的结果是直接进行 base64 加密的，方便后面直接使用。请记下这串字符。



## K8s 操作部分
安装依赖组件

此操作需要在所有的【K8s 节点】中进行，包括【K8s 控制节点】。


```
yum install ceph-common
```
#### 创建 ceph secret

```
apiVersion: v1
kind: Secret
metadata:
  name: ceph-admin-secret
  namespace: kube-system
data:
  key: "xxxxxxxxxxxxxx"
```

这里的 Key 部分填写上面【获取 admin 秘钥】部分输出的字符串，带引号。

这里的代码是 YAML，你可以直接把它复制到 Dashboard 的【创建】中执行。

你也可以将代码保存成 xxx.yaml 文件，然后在控制节点上执行命令 kubectl create -f xxx.yaml 。往下的内容也是如此。

### 部署 cephfs-provisoner

#### 创建命名空间

```
apiVersion: v1
kind: Namespace
metadata:
   name: cephfs
   labels:
     name: cephfs
```

#### 创建服务账户

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cephfs-provisioner
  namespace: cephfs
```

#### 创建角色

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cephfs-provisioner
  namespace: cephfs
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "get", "delete"]
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
```

#### 创建集群角色

```
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cephfs-provisioner
  namespace: cephfs
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
  - apiGroups: [""]
    resources: ["services"]
    resourceNames: ["kube-dns","coredns"]
    verbs: ["list", "get"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "create", "delete"]
  - apiGroups: ["policy"]
    resourceNames: ["cephfs-provisioner"]
    resources: ["podsecuritypolicies"]
    verbs: ["use"]
```

#### 绑定角色

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cephfs-provisioner
  namespace: cephfs
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cephfs-provisioner
subjects:
- kind: ServiceAccount
  name: cephfs-provisioner
```

#### 绑定集群角色

```
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cephfs-provisioner
subjects:
  - kind: ServiceAccount
    name: cephfs-provisioner
    namespace: cephfs
roleRef:
  kind: ClusterRole
  name: cephfs-provisioner
  apiGroup: rbac.authorization.k8s.io
```

#### 部署 cephfs-provisioner

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: cephfs-provisioner
  namespace: cephfs
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: cephfs-provisioner
    spec:
      containers:
      - name: cephfs-provisioner
        image: "quay.io/external_storage/cephfs-provisioner:latest"
        env:
        - name: PROVISIONER_NAME
          value: ceph.com/cephfs
        command:
        - "/usr/local/bin/cephfs-provisioner"
        args:
        - "-id=cephfs-provisioner-1"
        - "-disable-ceph-namespace-isolation=true"
      serviceAccount: cephfs-provisioner
```

#### 创建存储类

```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: cephfs
provisioner: ceph.com/cephfs
parameters:
    monitors: 192.168.10.101:6789,192.168.10.102:6789,192.168.10.103:6789
    adminId: admin
    adminSecretName: ceph-admin-secret
    adminSecretNamespace: "kube-system"
    claimRoot: /volumes/kubernetes
```

如果你只有一个 MON，“monitors” 这一项就填一个，末尾没有逗号。

“claimRoot” 用来设定 PV 创建在 Ceph 文件系统中的目录。

### 测试
#### 创建 PVC
```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-test
  annotations:
    volume.beta.kubernetes.io/storage-class: cephfs
    volume.beta.kubernetes.io/storage-provisioner: ceph.com/cephfs
spec:
  storageClassName: cephfs
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

#### 测试 POD
```
kind: Pod
apiVersion: v1
metadata:
  name: pod-test
spec:
  containers:
  - name: test-pod
    image: centos
    command:
      - "/bin/sh"
    args:
      - "-c"
      - "ping 127.0.0.1"
    volumeMounts:
      - name: pvc
        mountPath: "/mnt"
  restartPolicy: "Always"
  imagePullPolicy: IfNotPresent
  volumes:
    - name: pvc
      persistentVolumeClaim:
        claimName: pvc-test
  ```
