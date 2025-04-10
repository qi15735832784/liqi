# 自动检测CPU，内存，IO

## ✅ 一、目标实现

- **Shell 脚本**：当 CPU `%idle` < 30%，自动分析 CPU / 内存 / IO 哪块是瓶颈，找到高占用程序
- **Zabbix 触发器**：自动监控 `%idle`，并触发报警
- **报警消息中附带“瓶颈进程”信息**

------

## 🖥️ 二、Shell 脚本 `bottleneck_check.sh`

用于 Zabbix 执行触发后调用（也可以单独跑）

```
#!/bin/bash
# 脚本输出用于 Zabbix 自动集成，输出瓶颈信息
THRESHOLD=30
TMPFILE="/tmp/bottleneck_info.txt"

# 获取 idle
CPU_LINE=$(mpstat 1 1 | awk '/Average:/ && $2 == "all"')
IDLE=$(echo $CPU_LINE | awk '{print $NF}')
# ⛔ 防止空值
if [[ -z "$IDLE" ]]; then
    echo "❌ 获取 CPU idle 失败，请确认已安装 sysstat 包（包含 mpstat）"
    exit 1
fi

IDLE_INT=${IDLE%.*}

if [ "$IDLE_INT" -lt "$THRESHOLD" ]; then
    echo "⚠️ CPU idle: $IDLE% - 系统繁忙，开始分析瓶颈..." > "$TMPFILE"
    
    echo -e "\n👉 Top CPU 进程：" >> "$TMPFILE"
    ps -eo pid,ppid,user,cmd,%cpu --sort=-%cpu | head -n 5 >> "$TMPFILE"

    echo -e "\n👉 Top 内存 进程：" >> "$TMPFILE"
    ps -eo pid,ppid,user,cmd,%mem --sort=-%mem | head -n 5 >> "$TMPFILE"

    echo -e "\n👉 Top IO 进程：" >> "$TMPFILE"
    pidstat -d 1 1 | grep -v "^#" | sort -k 6 -nr | head -n 5 >> "$TMPFILE"

    cat "$TMPFILE"
else
    echo "✅ 系统正常，CPU idle: $IDLE%"
fi

```

### ✔️ 使用方式：

```
chmod +x /usr/local/bin/check.sh
```

你可以直接运行测试：

```
/usr/local/bin/check.sh
```

------

## 🔧 三、Zabbix 自定义监控 + 触发器

### 1. Zabbix Agent 配置自定义 Key

编辑 Zabbix Agent 配置：

```
vim /etc/zabbix_agentd.conf 
Server=10.15.200.134
ServerActive=10.15.200.134
Hostname=server
```

添加内容：

```
UserParameter=system.bottleneck.check,/usr/local/bin/check.sh
```

然后重启 Zabbix agent：

```
systemctl restart zabbix-agent
```

### 2. 在 Zabbix Server 添加监控项

- **名称**：系统瓶颈检查
- **键值**：`system.bottleneck.check`
- **类型**：Zabbix agent
- **更新间隔**：60s
- **类型**：文本类型

### 3. 添加触发器

- **触发器表达式**：

  ```
  #{your-hostname:system.cpu.util[,idle].last()}<30
  last(/System Bottleneck/system.bottleneck.check)<30
  ```

- **触发器名称**：

	```
	CPU idle < 30%，可能存在系统瓶颈
	```

- **严重等级**：Warning 或 High

### 4. 动作配置（报警消息）

你可以配置报警模板内容为：

```
主机: {HOST.NAME}
时间: {EVENT.DATE} {EVENT.TIME}
触发器: {TRIGGER.NAME}
当前值: {ITEM.VALUE}
--

系统瓶颈分析（手动查看）:
#zabbix_get -s {HOST.IP} -k system.bottleneck.check
zabbix_get -s 10.15.200.142 -k system.bottleneck.check
```