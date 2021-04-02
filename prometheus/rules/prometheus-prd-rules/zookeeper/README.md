# zookeeper告警策略配置文件

| 表达式                                                       | 说明                                                        | 级别     |
| ------------------------------------------------------------ | ----------------------------------------------------------- | -------- |
| up{service="zookeeper"} == 0                                 | Zookeeper 监控客户端挂了                                    | 严重告警 |
| zk_up == 0                                                   | Zookeeper 实例挂了！！！                                    | 严重告警 |
| sum by (id,project,environment,service,instance,user) (zk_server_leader{environment="prod"}) == 0 | Zookeeper 集群没有节点标记为leader                          | 严重告警 |
| sum by (id,project,environment,service,instance,user) (zk_server_leader{environment="prod"}) > 1 | Zookeeper 集群标记为leader的节点数大于1，可能发生脑裂！！！ | 严重告警 |
| zk_ruok == 0                                                 | Zookeeper 节点运行状态错误                                  | 严重告警 |
| zk_avg_latency > 10000                                       | Zookeeper 节点平均延时大于10s                               | 一般告警 |
| zk_znode_count > 100000                                      | Zookeeper 节点znode数量大于10万                             | 严重告警 |
| zk_approximate_data_size > 1073741824                        | Zookeeper 节点快照体积大于1G                                | 严重告警 |
| zk_open_file_descriptor_count / zk_max_file_descriptor_count * 100 > 70 | Zookeeper 节点打开文件描述符数量大于70%                     | 严重告警 |