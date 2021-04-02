**es 相关告警策略配置文件**

| 表达式                                                       | 说明                                    | 级别     |
| ------------------------------------------------------------ | --------------------------------------- | -------- |
| up{environment="prod",job="elasticsearch-exporter"} == 0     | 监控客户端挂了                          | 严重告警 |
| elasticsearch_cluster_health_up{environment="prod",job="elasticsearch-exporter"} == 0     | 获取集群监控数据失败                          | 严重告警 |
| elasticsearch_cluster_health_status{environment="prod",color="red"} == 1 | 集群健康状态为红色                      | 严重告警 |
| elasticsearch_cluster_health_status{environment="prod",color="yellow"} == 1 | 集群健康状态为黄色                      | 严重告警 |
| elasticsearch_cluster_health_unassigned_shards{environment="prod"} > 0 | 集群未分配的分片数量异常                | 一般告警 |
| rate(elasticsearch_breakers_tripped{environment="prod"}[5m]) > 0 | 周期5分钟内节点每秒熔断次数大于0        | 严重告警 |
| (elasticsearch_jvm_memory_pool_used_bytes{environment="prod",pool="old"} / elasticsearch_jvm_memory_pool_max_bytes{environment="prod",pool="old"}) * 100 > 90 | 节点 JVM OLD 区内存使用率超过90%        | 严重告警 |
| avg by(id,project,environment,service,instance) ((elasticsearch_jvm_memory_used_bytes{environment="prod",area="heap"}) / (elasticsearch_jvm_memory_max_bytes{environment="prod",area="heap"})) * 100 > 90 | 集群节点平均 JVM heap 内存使用率超过90% | 严重告警 |
| max by(id,project,environment,service,instance) ((elasticsearch_jvm_memory_used_bytes{environment="prod",area="heap"}) / (elasticsearch_jvm_memory_max_bytes{environment="prod",area="heap"})) * 100 > 90 | 集群节点最大 JVM heap 内存使用率超过90% | 严重告警 |
| rate(elasticsearch_jvm_gc_collection_seconds_count{environment="prod",gc="old"}[5m]) > 5 | 周期5分钟内节点每秒 Old GC 次数大于5    | 一般告警 |
| rate(elasticsearch_jvm_gc_collection_seconds_sum{environment="prod",gc="old"}[5m]) > 1 | 周期5分钟内节点每秒 Old GC 耗时大于1s   | 一般告警 |
| irate(elasticsearch_indices_search_query_total{environment="prod",es_data_node="true"}[5m]) > 10000 | 周期5分钟内节点每秒查询次数高于10000    | 一般告警 |
| irate(elasticsearch_indices_indexing_index_total{environment="prod",es_data_node="true"}[5m])  > 10000 | 周期5分钟内节点每秒写入次数高于10000    | 一般告警 |
| (irate((elasticsearch_thread_pool_rejected_count{environment="prod",type="search",es_data_node="true"}[1m])) / irate((elasticsearch_thread_pool_completed_count{environment="prod",type="search",es_data_node="true"}[1m]))) * 100 > 0 | 周期1分钟内节点每秒查询拒绝率大于0%     | 严重告警 |
| (irate(elasticsearch_thread_pool_rejected_count{environment="prod",type="write",es_data_node="true"}[1m]) / irate(elasticsearch_thread_pool_completed_count{environment="prod",type="write",es_data_node="true"}[1m])) * 100 > 0 | 周期1分钟内节点每秒写入拒绝率大于0%     | 严重告警 |
| (irate(elasticsearch_indices_indexing_index_time_seconds_total{environment="prod",es_data_node="true"}[1m]) / irate(elasticsearch_indices_indexing_index_total{environment="prod",es_data_node="true"}[1m])) * 1000 > 500 | 周期1分钟内节点每秒写入延迟大于500ms    | 一般告警 |
| (irate(elasticsearch_indices_search_query_time_seconds{environment="prod",es_data_node="true"}[1m]) / irate(elasticsearch_indices_search_query_total{environment="prod",es_data_node="true"}[1m])) * 1000 > 500 | 周期1分钟内节点每秒查询延迟大于500ms    | 一般告警 |
| elasticsearch_process_cpu_percent{environment="prod"} > 95   | 节点进程 CPU 使用率超过95%              | 严重告警 |
| elasticsearch_os_cpu_percent{environment="prod"} > 95        | 节点主机 CPU 使用率超过95%              | 严重告警 |
| (sum by(id,project,environment,service,instance) (elasticsearch_filesystem_data_size_bytes{environment="prod"} - elasticsearch_filesystem_data_available_bytes{environment="prod"})) / sum by(id,project,environment,service,instance) (elasticsearch_filesystem_data_size_bytes{environment="prod"}) * 100 > 82 | 集群总磁盘使用率超过82%                 | 严重告警 |
| max by(id,host,project,environment,service,instance,mount) ((elasticsearch_filesystem_data_size_bytes{environment="prod"} - elasticsearch_filesystem_data_available_bytes{environment="prod"}) / elasticsearch_filesystem_data_size_bytes{environment="prod"}) * 100 > 83 | 节点最大磁盘使用率超过83%              | 严重告警 |
| elasticsearch_process_open_files_count{environment="prod"} / elasticsearch_process_max_files_descriptors{environment="prod"} * 100 > 70        | 节点打开文件描述符数量大于70%              | 严重告警 |
| delta(elasticsearch_cluster_health_number_of_nodes{environment="prod"}[5m]) < 0        | 在线节点数异常，请检查集群中在线节点数是否正常              | 严重告警 |
| elasticsearch_cluster_health_number_of_nodes{environment="prod",id="gztxy-erp-prd-crm-es01-10.124.105.2-elasticsearch"} < 17 | 集群在线节点数少于17个                  | 严重告警 |