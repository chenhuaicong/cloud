# kafka 相关告警策略配置文件

| 表达式                                                       | 说明                         | 级别     |
| ------------------------------------------------------------ | ---------------------------- | -------- |
| up{environment=~"pro?d", service="kafka"} == 0                    | 监控客户端挂了         | 严重告警 |
| delta(kafka_brokers{environment=~"pro?d"}[5m]) < 0                          | 在线节点数异常，请检查集群中在线节点数是否正常         | 严重告警 |
| sum(kafka_consumergroup_lag{environment=~"pro?d",id!~".*elk.*"}) by (consumergroup,topic,environment,project,instance,id,service,user) > 150000 | 消费组 topic 堆积数超过15万条        | 严重告警 |
| sum(rate(kafka_topic_partition_current_offset{environment=~"pro?d",id!~".*elk.*"}[1m])) by (topic,environment,project,instance,id,service,user) > 5000 | 每秒消息产生数超过2000条         | 严重告警 |
| up{ environment=~"pro?d",job="kafka-jmx"} == 0                    |  Jmx 监控客户端挂了        | 严重告警 |
| kafka_operatingsystem_openfiledescriptorcount{environment=~"pro?d"} / kafka_operatingsystem_maxfiledescriptorcount{environment=~"pro?d"} * 100 > 70                    | 打开文件描述符数量大于70%         | 严重告警 |
| rate(kafka_old_gc_collectioncount{environment=~"pro?d"}[5m]) > 5                    | 周期5分钟内每秒 Old GC 次数大于5         | 一般告警 |
| rate(kafka_old_gc_collectiontime{environment=~"pro?d"}[5m]) > 1000                  | 周期5分钟内每秒 Old GC 耗时大于1s          | 一般告警 |
| kafka_threading_threadcount{environment=~"pro?d"} > 150                    | 活跃线程数大于150         | 一般告警 |
| kafka_controller_kafkacontroller_offlinepartitionscount{environment=~"pro?d"} > 1                    | 没有Leader的分区数大于1         | 严重告警 |
| rate(kafka_network_requestmetrics_errors_total{environment=~"pro?d",request="Fetch, error=UNKNOWN_TOPIC_OR_PARTITION"}[5m]) > 10                    |每秒unkown_parttion错误量大于10          | 严重告警 |
| rate(kafka_network_requestmetrics_errors_total{environment=~"pro?d",request="Heartbeat, error=REBALANCE_IN_PROGRESS"}[5m]) > 10                    | 消费者整体重平衡每秒syncgroup错误量大于10         | 严重告警 |