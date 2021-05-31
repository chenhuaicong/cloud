
## 部署rabbitmq cluster operator

```
oc apply -f https://raw.githubusercontent.com/chenhuaicong/cloud/master/openshift/operator/rabbitmq/cluster-operator.yml

namespace/rabbitmq-system created
customresourcedefinition.apiextensions.k8s.io/rabbitmqclusters.rabbitmq.com created
serviceaccount/rabbitmq-cluster-operator created
role.rbac.authorization.k8s.io/rabbitmq-cluster-leader-election-role created
clusterrole.rbac.authorization.k8s.io/rabbitmq-cluster-operator-role created
rolebinding.rbac.authorization.k8s.io/rabbitmq-cluster-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/rabbitmq-cluster-operator-rolebinding created
deployment.apps/rabbitmq-cluster-operator created
```

#### 这个配置文件做了几处修改：

1.修改cluster-operator和rabbitmq镜像为本地registry.

```
[root@szzb-ocp4-dev-base rabbitmq]# grep  -b1 image: cluster-operator.yml 
40386-                type: object
40415:              image:
40436-                default: harbor.ky-tech.com.cn/base/rabbitmq:3.8.16-management
--
71823-                                          type: array
71877:                                        image:
71924-                                          type: string
--
106293-                                          type: array
106347:                                        image:
106394-                                          type: string
--
140672-                                          type: array
140726:                                        image:
140773-                                          type: string
--
211642-                                              type: string
211701:                                            image:
211752-                                              type: string
--
243895-              fieldPath: metadata.namespace
243939:        image: harbor.ky-tech.com.cn/rabbitmqoperator/cluster-operator:1.7.0
244016-        name: operator

```
此外，还可以根据本地仓库的公开还有私有添加身份认证

```
kubectl -n rabbitmq-system create secret \
docker-registry rabbitmq-cluster-registry-access \
--docker-server=DOCKER-SERVER \
--docker-username=DOCKER-USERNAME \
--docker-password=DOCKER-PASSWORD
```
Where:

- DOCKER-SERVER is the server URL for your private image registry.
- DOCKER-USERNAME is your username for your private image registry authentication.
- DOCKER-PASSWORD is your password for your private image registry authentication.


For Example:

```
kubectl -n rabbitmq-system create secret \
docker-registry rabbitmq-cluster-registry-access \
--docker-server=docker.io/my-registry \
--docker-username=my-username \
--docker-password=example-password1
```

然后更新operator的serviceaccount

```
kubectl -n rabbitmq-system patch serviceaccount \
rabbitmq-cluster-operator -p '{"imagePullSecrets": [{"name": "rabbitmq-cluster-registry-access"}]}'
```



2.修改namespace annotations:

```
apiVersion: v1
kind: Namespace
metadata:
  annotations:
...
    openshift.io/sa.scc.supplemental-groups: 1000/1
    openshift.io/sa.scc.uid-range: 1000/1
    openshift.io/sa.scc.mcs: 's0:c26,c5'
```

3.创建一个SCC（安全上下文约束），允许 RabbitMQ pod 具有FOWNER和CHOWN 功能：

```
oc apply -f rabbitmq-scc.yml
```
scc的内容如下：

```
kind: SecurityContextConstraints
apiVersion: security.openshift.io/v1
metadata:
  name: rabbitmq-cluster
allowPrivilegedContainer: false
runAsUser:
  type: MustRunAsRange
seLinuxContext:
  type: MustRunAs
fsGroup:
  type: MustRunAs
supplementalGroups:
  type: RunAsAny
requiredDropCapabilities:
  - "ALL"
allowedCapabilities:
  - "FOWNER"
  - "CHOWN"
  - "DAC_OVERRIDE"
volumes:
  - "configMap"
  - "secret"
  - "persistentVolumeClaim"
  - "downwardAPI"
  - "emptyDir"
  - "projected"
```
4. 对于将创建 RabbitMQ集群自定义资源的每个命名空间（这里我们假设为my-rabbitmq命名空间），更改以下字段：

```
oc edit namespace default
```

```
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    ...
    openshift.io/sa.scc.supplemental-groups: 999/1
    openshift.io/sa.scc.uid-range: 0-999
```

或者通过命令行的方式进行更新

```
oc patch namespace my-rabbitmq -p '{"metadata":{"annotations":{"openshift.io/sa.scc.supplemental-groups":"999/1"}}}'
oc patch namespace my-rabbitmq -p '{"metadata":{"annotations":{"openshift.io/sa.scc.uid-range":"0-999"}}}'
```


5. 对于每个 RabbitMQ 集群（这里我们假设新创建的集群名称为my-rabbitmq）将之前创建的安全上下文约束分配给集群的服务帐户。


```
oc adm policy add-scc-to-user rabbitmq-cluster -z my-rabbitmq-server -n my-rabbitmq 
securitycontextconstraints.security.openshift.io/rabbitmq-cluster added to: ["system:serviceaccount:my-rabbitmq:my-rabbitmq-server"]
```

6.现在我们可以开始创建demo rabbitmq集群，名称叫做my-rabbitmq

```
oc apply -f https://raw.githubusercontent.com/chenhuaicong/cloud/master/openshift/operator/rabbitmq/my-rabbitmq.yaml  -n my-rabbitmq
```
这里我增加了选择Storageclass的配置和时区修改
```
apiVersion: rabbitmq.com/v1beta1
kind: RabbitmqCluster
metadata:
  name: my-rabbitmq
spec:
  replicas: 3
  persistence:
   storageClassName: csi-cephfs-sc
   storage: 20Gi
  override:
    statefulSet:
      spec:
        template:
          spec:
            containers:
              - name: rabbitmq
                env:
                  - name: TZ
                    value: Asia/Shanghai
```
