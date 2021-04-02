**redis 相关告警策略配置文件**

| 表达式                                                       | 说明                         | 级别     |
| ------------------------------------------------------------ | ---------------------------- | -------- |
| up{environment=~"pro?d",job="redis"} == 0                    | Redis 监控客户端挂了         | 严重告警 |
| redis_up{environment=~"pro?d"} == 0                          | Redis 实例挂了！！！         | 严重告警 |
| redis_memory_used_bytes{environment=~"pro?d"} / redis_memory_max_bytes{environment=~"pro?d"} * 100 > 90 | Redis 内存使用超过90%        | 严重告警 |
| redis_connected_clients{environment=~"pro?d"} / redis_config_maxclients{environment=~"pro?d"} * 100 > 90 | Redis 连接数超过90%          | 严重告警 |
| increase(redis_rejected_connections_total{environment=~"pro?d"}[1m]) > 0 | Redis 连接被拒绝             | 一般告警 |
| redis_db_keys{environment=~"pro?d"} > 20000000               | Redis KEY 的数量过多         | 一般告警 |
| changes(redis_connected_slaves{environment=~"pro?d"}[1m]) > 1 | Redis 从库连接有发生过变更   | 一般告警 |
| delta(redis_connected_slaves{environment=~"pro?d"}[5m]) < 0  | Redis 从库复制发生中断       | 严重告警 |
| rate(redis_evicted_keys_total{environment=~"pro?d"}[5m]) > 1 | Redis 周期5分钟内驱逐数大于1 | 严重告警 |
| redis_master_link_up{environment=~"pro?d"} == 0              | Redis 主从连接异常           | 严重告警 |
| (rate(redis_cpu_sys_seconds_total{environment=~"pro?d"}[1m]) + rate(redis_cpu_user_seconds_total{environment=~"pro?d"}[1m])) * 100 > 90             | Redis CPU使用率大于90%           | 严重告警 |
| rate(redis_net_output_bytes_total{environment=~"pro?d",id!="gztxy-kuasheng-prd-msg01-10.124.103.197-redis"}[5m]) / 1024 / 1024 > 100              | Redis 出口流量大于100M           | 严重告警 |