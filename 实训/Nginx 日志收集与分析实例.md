# Nginx 日志收集与分析实例

## 一、基础统计分析

### 1. 请求量统计

```
wc -l access.log
```

### 2. 访问量最高的 20 个 IP

```
awk '{print $1}' access.log | sort | uniq -c | sort -nr | head -20
```

### 3. 热门 URL 统计

```
awk '{print $7}' access.log | sort | uniq -c | sort -nr | head -20
```

------

## 二、高级分析

### 4. 恶意 IP 检测（短时间内请求 > 100 次）

```
awk '{print $1,$4}' access.log | cut -d: -f1-2 | uniq -c | awk '$1>100'
```

### 5. 慢请求分析（响应时间 > 5 秒）

假设响应时间为最后一列 `$NF`

```
awk '$NF > 5' access.log
```

### 6. 带宽消耗分析（单位：MB）

```
awk '{sum+=$10} END {print sum/1024/1024 " MB"}' access.log
```

------

## 三、时间维度分析

### 7. 每小时请求量统计

```
awk '{print substr($4, 14, 2)}' access.log | sort | uniq -c
```

### 8. 高峰时段识别（精确到分钟）

```
awk '{print substr($4, 14, 5)}' access.log | sort | uniq -c | sort -nr | head -10
```

### 9. 周末/工作日对比（识别访问模式）

```
awk -F'[/:]' '{print $1}' access.log | while read ip; do
  date=$(grep $ip access.log | head -1 | awk -F[/:] '{print $2"/"$3"/"$4}')
  day=$(date -d "$date" +%u)
  echo $day
done | sort | uniq -c
```

------

## 四、用户行为分析

### 10. 用户访问深度分析（每 IP 的访问页面数）

```
awk '{ips[$1]++} END {for (ip in ips) print ip, ips[ip]}' access.log | sort -k2 -nr
```

### 11. 新老访客识别

```
awk '{print $1}' access.log | sort | uniq -c | awk '$1==1 {print $2}' > new_visitors.txt
awk '{print $1}' access.log | sort | uniq -c | awk '$1>1 {print $2}' > returning_visitors.txt
```

------

## 五、安全分析 / 性能优化

### 12. 大文件传输分析（单次传输 > 1MB）

```
awk '$10 > 1048576' access.log
```

------

## 六、推荐工具

- **GoAccess** 可视化日志分析：

	```
	goaccess access.log -o report.html --log-format=COMBINED
	```

- **ELK Stack / Grafana + Loki** 适合大规模实时监控和可视化