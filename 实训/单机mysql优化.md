# 单机mysql优化

MySQL 优化可以从多个层面进行，通常分为以下几个方向：**硬件优化、系统优化、配置优化、SQL 语句优化**。下面我分别详细说说：

------

### 一、硬件方面的优化

硬件是性能的基础，尤其在高并发或大数据量场景下更明显。

1. **CPU**
   - 提高 CPU 主频，提升单线程性能（MySQL 单线程瓶颈明显）。
   - 增加 CPU 核数，利于并发连接（适用于 InnoDB）。
2. **内存**
   - 增加内存，尽可能让 MySQL 缓存（如 buffer pool）和热数据全装入内存，减少磁盘 IO。
3. **磁盘（IO 性能）**
   - 使用 SSD 替代机械硬盘，提升读写速度。
   - 配置 RAID 10 提高 IO 性能和数据安全性。
4. **网络**
   - 高并发读写场景，注意网络带宽瓶颈，尽量使用千兆或万兆网络。
   - 连接数多时可考虑使用连接池技术。

------

### 二、操作系统方面的优化（以 Linux 为例）

系统层面对 MySQL 性能也有不小影响：

1. **文件句柄限制**
   - 提高 `ulimit -n` 和 `/etc/security/limits.conf` 中的文件打开数，避免连接数高时报错。
2. **内核参数优化**
   - `vm.swappiness=1`：尽量少使用交换空间。
   - `net.core.somaxconn`、`net.ipv4.tcp_max_syn_backlog`：提高连接排队能力。
   - 调整磁盘调度算法，如将 `/sys/block/sdX/queue/scheduler` 改为 `noop` 或 `deadline`。
3. **NUMA 设置**
   - 对于多 CPU 服务器，建议禁用 NUMA 或设置好 `numactl`，避免内存访问跨 NUMA 节点。
4. **关闭透明大页（THP）**
   - 可能引发性能抖动，可通过 `grub` 配置关闭。

------

### 三、MySQL 配置优化（my.cnf）

合理的配置是性能调优的关键，以下以 InnoDB 为主：

1. **InnoDB 缓冲池**

   ```
   ini复制编辑innodb_buffer_pool_size = 70-80% of total memory
   innodb_buffer_pool_instances = CPU 核心数（通常 4~8）
   ```

2. **Redo/Undo 日志配置**

   ```
   ini复制编辑innodb_log_file_size = 1G（结合写入压力调优）
   innodb_log_buffer_size = 64M
   ```

3. **连接数设置**

   ```
   ini复制编辑max_connections = 根据业务压力设置，如 500 ~ 2000
   wait_timeout = 600（防止连接泄漏）
   ```

4. **查询缓存（MySQL 5.7 以下）**

   - 对于高并发读少写的场景有效：

     ```
     ini复制编辑query_cache_type = 1
     query_cache_size = 64M
     ```

5. **慢查询日志**

   - 打开慢查询日志，辅助发现慢 SQL：

     ```
     ini复制编辑slow_query_log = ON
     long_query_time = 1
     ```

------

### 四、SQL 语句优化（最关键）

SQL 是性能优化的根本，建议从以下角度考虑：

1. **索引**
   - 覆盖索引（select 的列全在索引里）。
   - 联合索引顺序优化（最左前缀原则）。
   - 避免在 WHERE 条件中对列使用函数或计算。
2. **EXPLAIN 分析**
   - 使用 `EXPLAIN` 查看执行计划，判断是否走了索引，是否有全表扫描等问题。
3. **避免典型慢 SQL**
   - SELECT *（改为明确字段）
   - 子查询（尽量改为 JOIN）
   - 使用 `%like%`、OR 多条件等
4. **LIMIT 优化**
   - 大分页时避免 offset 很大，使用 `WHERE id > 上一页最大值` 替代。
5. **事务控制**
   - 避免长事务，减少锁等待和死锁。

------

### 小结一句话：

> 硬件是地基，系统是框架，配置是工具，SQL 是灵魂。



“MySQL 优化我一般从 SQL 优化、索引优化、表结构设计、MySQL 配置参数、以及分库分表这几个方向来入手。比如定位慢查询后用 EXPLAIN 看有没有全表扫描，必要时添加覆盖索引；如果是大表还可以考虑分表或读写分离；同时也会根据业务类型调整 MySQL 参数，比如增加 buffer pool 来提高缓存命中率。再搭配监控系统比如 Zabbix 或 Prometheus 实时观察慢 SQL 和 QPS 波动。”