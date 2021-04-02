# rabbitmq 相关告警策略配置文件


| 表达式                                                       | 说明                         | 级别     |
| ------------------------------------------------------------ | ---------------------------- | -------- |
| up{environment="prod",job="rabbitmq"} == 0                    | Rabbitmq 监控客户端挂了或者实例无响应！！！         | 严重告警 |
| rabbitmq_up{environment="prod"} == 0                          | Rabbitmq 实例挂了！！！         | 严重告警 |
| rabbitmq_node_mem_used{environment="prod",self="1"} / rabbitmq_node_mem_limit{environment="prod",self="1"} * 100 > 90 | Rabbitmq 内存使用超过90%        | 严重告警 |
| rabbitmq_node_disk_free{environment="prod",self="1"} < rabbitmq_node_disk_free_limit{environment="prod",self="1"} * 20 | Rabbitmq 磁盘可用空间不足         | 严重告警 |
| rabbitmq_connections{environment="prod"} > 1000                    |Rabbitmq 连接数过多         | 一般告警 |
| rabbitmq_queue_messages_ready{environment="prod",self="1"} > 10000     | Rabbitmq 虚拟主机 队列 消息积压数大于1万         | 严重告警 |
| rabbitmq_fd_used{environment="prod",self="1"} / rabbitmq_fd_available{environment="prod",self="1"} * 100 > 70     | Rabbitmq 节点打开文件描述符数量大于70%         | 严重告警 |