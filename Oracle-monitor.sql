--dbfilesize=数据库文件大小，浮点数，单位：MB（为什么要除以10？）
SELECT sum(bytes/1024/1024/10), 'FM99999999999999990' retvalue FROM dba_data_files;
--SELECT sum(bytes/1024/1024/10) retvalue FROM dba_data_files;

--dbsize=数据库大小，浮点数，单位：MB（为什么要除以10？）
SELECT sum(  NVL(a.bytes/1024/1024/10 - NVL(f.bytes/1024/1024/10, 0), 0)), 'FM99999999999999990' retvalue 
FROM sys.dba_tablespaces d,
(SELECT tablespace_name, sum(bytes) bytes FROM dba_data_files GROUP BY tablespace_name) a,
(SELECT tablespace_name, sum(bytes) bytes FROM dba_free_space GROUP BY tablespace_name) f
WHERE d.tablespace_name = a.tablespace_name(+) AND d.tablespace_name = f.tablespace_name(+)
AND NOT (d.extent_management LIKE 'LOCAL' AND d.contents LIKE 'TEMPORARY');

--rman_check_status=备份和恢复操作状态检查（没有解决查不到记录返回true和false）
SELECT ' DB NAME->'||DB_NAME||'- ROW TYPE->'||ROW_TYPE||'- START TIME->'||to_number(start_time, 'Dy DD-Mon-YYYY HH24:MI:SS') ||'- END TIME->'||to_number(end_time, 'Dy DD-Mon-YYYY HH24:MI:SS')||'- MBYTES PROCESSED->'||MBYTES_PROCESSED||'- OBJECT TYPE->'||OBJECT_TYPE||'- STATUS->'||STATUS||'- OUTPUT DEVICE->'||OUTPUT_DEVICE_TYPE||'- INPUT MB->'||INPUT_BYTES/1048576||'- OUT MB'||OUTPUT_BYTES/1048576 
FROM rc_rman_status WHERE  start_time > SYSDATE - 1 AND ( STATUS LIKE '%FAILED%' OR  STATUS LIKE '%ERROR%') 
ORDER  BY END_TIME;
--SELECT nvl2(status,'false','true') FROM v$RMAN_STATUS WHERE status IS NULL;
--SELECT nvl2(count(*),'true','false') FROM v$librarycache
--SELECT status FROM v$RNAN
--SELECT rownum FROM v$RMAN_STATUS;
--SELECT status, CASE WHEN count(status)<=1 THEN 0 ELSE 1 FROM v$RMAN_STATUS ;

--uptime=数据库启用时长，整数，单位：秒
SELECT (sysdate-startup_time)*86400, 'FM99999999999999990' retvalue FROM v$instance;

--users_locked=用户锁，字符串（没有解决查不到记录返回true和false）
SELECT username||' '|| lock_date ||' '|| account_status FROM dba_users WHERE ACCOUNT_STATUS LIKE 'EXPIRED(GRACE)' OR ACCOUNT_STATUS LIKE 'LOCKED(TIMED)';

--archive=日志归档大小，浮点数，单位：MB
SELECT round(A.LOGS*B.AVG/1024/1024/10) FROM ( SELECT COUNT (*)  LOGS FROM V$LOG_HISTORY WHERE FIRST_TIME >= (sysdate -10/60/24)) A, ( SELECT Avg(BYTES) AVG,  Count(1), Max(BYTES) Max_Bytes, Min(BYTES) Min_Bytes  FROM  v$log) B;

--archive_race_condition=日志归档状态，字符串
SELECT value FROM v$parameter WHERE name='log_archive_start';

--audit=审计详情，字符串
SELECT username "username", timestamp,'DD-MON-YYYY HH24:MI:SS' "time_stamp", action_name "statement", 
os_username "os_username", userhost "userhost", 
returncode||decode(returncode,'1004','-Wrong Connection','1005','-NULL Password','1017','-Wrong Password','1045','-Insufficient Priviledge','0','-Login Accepted','--') "returncode"
FROM sys.dba_audit_session
WHERE (sysdate - TIMESTAMP)*24 < 1 AND returncode <> 0
ORDER BY TIMESTAMP;

--dbblockgets=当前请求块的数目，整数，单位：个
SELECT sum(decode(name,'db block gets', value,0)) "block_gets" FROM v$sysstat;

--dbconsistentgets=数据请求总数在回滚段Buffer中的数据一致性读所需要的数据块，整数，单位：个
SELECT sum(decode(name,'consistent gets', value,0)) "consistent_gets" FROM v$sysstat;

--dbhitratio=数据命中率，浮点数，单位100
SELECT (
sum(decode(name,'consistent gets', value,0)) + sum(decode(name,'db block gets', value,0)) - sum(decode(name,'physical reads', value,0))
) / (sum(decode(name,'consistent gets', value,0)) + sum(decode(name,'db block gets', value,0)) ) * 100 "hit_ratio"
FROM v$sysstat;

--dbphysicalread=数据物理读写次数，整数
SELECT sum(decode(name,'physical reads', value,0)) "phys_reads" FROM v$sysstat;

--dbversion=数据库版本，字符串

--SELECT COMP_ID||' '||COMP_NAME||' '||VERSION||' '||STATUS||' <br />' 
--FROM dba_registry 
--UNION SELECT ' - SERVERNAME = <b>'||UTL_INADDR.get_host_name ||'</b> - SERVERADDRESS = <b>'||UTL_INADDR.get_host_address||'</b> <br />'
--FROM dual 
--UNION SELECT ' - DB_NAME = <b>'||SYS_CONTEXT ('USERENV', 'DB_NAME') ||'</b> - INSTANCE_NAME = <b>' ||SYS_CONTEXT ('USERENV', 'INSTANCE_NAME')||'</b> <br />' 
--FROM dual;
select CONCAT(PRODUCT,VERSION) from product_component_version WHERE PRODUCT LIKE 'Or%' AND  rownum =1;

--sqlnotindexed=未索引的sql比率，浮点数，单位1
SELECT 
SUM(DECODE(NAME, 'table scans (long tables)', VALUE, 0)) 
/ (SUM(DECODE(NAME, 'table scans (long tables)', VALUE, 0))+SUM(DECODE(NAME, 'table scans (short tables)', VALUE, 0))) 
*100 SQL_NOT_INDEXED 
FROM V$SYSSTAT WHERE 1=1 AND ( NAME IN ('table scans (long tables)','table scans (short tables)') );

--hitratio_body=body缓存区命中率，浮点数，单位100
SELECT gethitratio*100 "get_pct" FROM v$librarycache WHERE namespace ='BODY';

--hitratio_sqlarea=SQL区缓存命中率，浮点数，单位100
SELECT gethitratio*100 "get_pct" FROM v$librarycache WHERE namespace ='SQL AREA';

--hitratio_trigger=触发器缓存命中率，浮点数，单位100
SELECT gethitratio*100 "get_pct" FROM v$librarycache WHERE namespace ='TRIGGER';

--hitratio_table_proc=表/程序缓存命中率，浮点数，单位100
SELECT gethitratio*100 "get_pct" FROM v$librarycache WHERE namespace = 'TABLE/PROCEDURE';

--lio_block_changes=逻辑IO块改变速率，整数，单位：Blocks/sec
SELECT SUM(DECODE(NAME,'db block changes',VALUE,0)) FROM V$SYSSTAT WHERE NAME ='db block changes';

--lio_consistent_read=逻辑IO块一致性读速率，整数，单位：Blocks/sec
SELECT sum(decode(name,'consistent gets',value,0)) FROM V$SYSSTAT WHERE NAME ='consistent gets';

--lio_current_read=逻辑IO块当前读速率，整数，单位：Blocks/sec
SELECT sum(decode(name,'db block gets',value,0)) FROM V$SYSSTAT WHERE NAME ='db block gets';

--locks=查询锁详情，字符串
SELECT b.session_id AS sid, NVL(b.oracle_username, '(oracle)') AS username, a.owner AS object_owner, 
a.object_name, 
Decode(b.locked_mode, 0, 'None',
      1, 'Null (NULL)',
      2, 'Row-S (SS)',
      3, 'Row-X (SX)',
      4, 'Share (S)',
      5, 'S/Row-X (SSX)',
      6, 'Exclusive (X)',
       b.locked_mode) locked_mode, b.os_user_name 
FROM dba_objects a, v$locked_object b
WHERE  a.object_id = b.object_id
ORDER BY 1, 2, 3, 4;

--maxprocs=查询数据库允许的最大连接数，整数，单位：个
SELECT value "maxprocs" FROM v$parameter WHERE name ='processes';


--maxsession=查询数据库允许的最大会话数，整数，单位：个
SELECT value "maxsess" FROM v$parameter WHERE name ='sessions';

--select sid,serial#,username,program,machine,status from v$session;

--Latch 是一种低级排队(串行)机制,用于保护 SGA 中共享内存结构
--Latch 是一种快速的被获取和释放的内存锁,用于防止共享内存结构被多个用户同时访问

--miss_latch=latch初次尝试请求不成功次数，整数，单位：个
SELECT SUM(misses) FROM V$LATCH

--（pga是有疑惑的）
--pga_aggregate_target=指定所有session总计可以使用最大数，单位：个
SELECT decode( unit,'bytes', value/1024/1024, value),'999999999.9' value FROM V$PGASTAT WHERE name IN 'aggregate PGA target parameter';

--pga=总pga使用率，浮点数，单位100
SELECT decode( unit,'bytes', value/1024/1024, value),'999999999.9' value FROM V$PGASTAT WHERE name IN 'total PGA inuse';

--phio_datafile_reads=重做日志缓冲区每秒读取次数，整数，单位：IO/sec
SELECT sum(decode(name,'physical reads direct',value,0)) FROM V$SYSSTAT WHERE name ='physical reads direct';

--phio_datafile_writes=重做日志缓冲区每秒写入次数，整数，单位：IO/sec
SELECT sum(decode(name,'physical writes direct',value,0)) FROM V$SYSSTAT WHERE name ='physical writes direct';

--https://docs.oracle.com/cd/B16240_01/doc/doc.102/e16282/oracle_database_help/oracle_database_instance_throughput_redowrites_ps.html
--phio_redo_writes=重做日志缓冲区采样周期内每秒的重做写操作次数，整数，单位：IO/sec
SELECT sum(decode(name,'redo writes',value,0)) FROM V$SYSSTAT WHERE name ='redo writes';

--pinhitratio_body=库缓存body命中pin比率，浮点数，单位100
SELECT pins/(pins+reloads)*100 "pin_hit ratio" FROM v$librarycache WHERE namespace ='BODY';
--SELECT PINHITRATIO*100 "pin_hit ratio" FROM v$librarycache WHERE namespace ='BODY';
--SELECT (PINHITS/pins)*100 FROM v$librarycache WHERE namespace ='BODY';

--pinhitratio_sqlarea=库缓存sql区命中pin比率，浮点数，单位100
SELECT pins/(pins+reloads)*100 "pin_hit ratio" FROM v$librarycache WHERE namespace ='SQL AREA';

--pinhitratio_table_proc=库缓存表/程序命中pin比率，浮点数，单位100
SELECT pins/(pins+reloads)*100 "pin_hit ratio" FROM v$librarycache WHERE namespace ='TABLE/PROCEDURE';

--pinhitratio_trigger=库缓存触发器命中pin比率，浮点数，单位100
SELECT pins/(pins+reloads)*100 "pin_hit ratio" FROM v$librarycache WHERE namespace ='TRIGGER';

--pool_dict_cache=共享池字典缓存大小，浮点数，单位：MB
SELECT ROUND(SUM(decode(pool,'shared pool',decode(name,'dictionary cache',(bytes)/(1024*1024),0),0)),2) pool_dict_cache FROM V$SGASTAT;

--pool_free_mem=共享池空闲内存，浮点数，单位：MB
SELECT ROUND(SUM(decode(pool,'shared pool',decode(name,'free memory',(bytes)/(1024*1024),0),0)),2) pool_free_mem FROM V$SGASTAT;

--pool_lib_cache=共享池库缓存，浮点数，单位：MB
SELECT ROUND(SUM(decode(pool,'shared pool',decode(name,'library cache',(bytes)/(1024*1024),0),0)),2) pool_lib_cache FROM V$SGASTAT;

--pool_misc=共享池杂项，浮点数，单位：MB
SELECT ROUND(SUM(decode(pool,'shared pool',decode(name,'library cache',0,'dictionary cache',0,'free memory',0,'sql area', 0,(bytes)/(1024*1024)),0)),2) pool_misc FROM V$SGASTAT;

--pool_sql_area=共享池sql区缓存，浮点数，单位：MB
SELECT ROUND(SUM(decode(pool,'shared pool',decode(name,'sql area',(bytes)/(1024*1024),0),0)),2) pool_sql_area FROM V$SGASTAT;

--procnum=查询数据库当前进程的连接数，整数，单位：个
SELECT count(*) "procnum" FROM v$process;


--session_active=查询数据库并发的连接数，单位：个
SELECT count(*) FROM v$session WHERE TYPE!='BACKGROUND' AND status='ACTIVE';

--session_inactive=非活动状态会话，单位：个
SELECT SUM(Decode(Type, 'BACKGROUND', 0, Decode(Status, 'ACTIVE', 0, 1))) FROM V$SESSION;
--SELECT count(*) FROM v$session WHERE TYPE!='BACKGROUND' AND status='INACTIVE';

--session=查询数据库当前的连接数，单位：个
SELECT count(*) FROM v$session;


--session_system=查询数据库系统的连接数，单位：个
SELECT SUM(Decode(Type, 'BACKGROUND', 1, 0)) system_sessions FROM V$SESSION;

--SGA系统全局区的英文简称，SGA （System Global Area）是Oracle Instance的 基本组成部分，在实例启动时分配。
--是一组包含一个Oracle实例的数据和控制信息的共享内存结构。主要是用于存储数据库信息的内存区，
--该信息为数据库进程所共享（PGA不能共享的）。它包含Oracle 服务器的数据和控制信息，它是在
--Oracle服务器所驻留的计算机的实际内存中得以分配，如果实际内存不够再往虚拟内存中写。

--sga_buffer_cache=sga数据高速缓冲区大小，单位：MB
SELECT ROUND(SUM(decode(pool,NULL,decode(name,'db_block_buffers',(bytes)/(1024*1024),'buffer_cache',(bytes)/(1024*1024),0),0)),2) sga_bufcache FROM V$SGASTAT;

--sga_fixed=SGA固定组件大小，单位：MB
SELECT ROUND(SUM(decode(pool,NULL,decode(name,'fixed_sga',(bytes)/(1024*1024),0),0)),2) sga_fixed FROM V$SGASTAT;

--sga_java_pool=sga java池大小，单位：MB
SELECT ROUND(SUM(decode(pool,'java pool',(bytes)/(1024*1024),0)),2) sga_jpool FROM V$SGASTAT;

--sga_large_pool=sga大池大小，单位：MB
SELECT ROUND(SUM(decode(pool,'large pool',(bytes)/(1024*1024),0)),2) sga_lpool FROM V$SGASTAT;

--sga_log_buffer=sga日志缓存区大小，单位：MB
SELECT ROUND(SUM(decode(pool,NULL,decode(name,'log_buffer',(bytes)/(1024*1024),0),0)),2) sga_lbuffer FROM V$SGASTAT;

--sga_shared_pool=sga共享池大小，单位：MB
SELECT ROUND(SUM(decode(pool,'shared pool',decode(name,'library cache',0,'dictionary cache',0,'free memory',0,'sql area',0,(bytes)/(1024*1024)),0)),2) pool_misc FROM V$SGASTAT;

--tbl_space=为特定的表分配的所有页的逻辑集合详情
SELECT * FROM (
    SELECT '- Tablespace ->',t.tablespace_name ktablespace, 
    '- Type->',substr(t.contents, 1, 1) tipo,
    '- Used(MB)->',trunc((d.tbs_size-nvl(s.free_space, 0))/1024/1024) ktbs_em_uso,
    '- ActualSize(MB)->',trunc(d.tbs_size/1024/1024) ktbs_size,
    '- MaxSize(MB)->',trunc(d.tbs_maxsize/1024/1024) ktbs_maxsize,
    '- FreeSpace(MB)->',trunc(nvl(s.free_space, 0)/1024/1024) kfree_space,
    '- Space->',trunc((d.tbs_maxsize - d.tbs_size + nvl(s.free_space, 0))/1024/1024) kspace,
    '- Perc->',decode(d.tbs_maxsize, 0, 0, trunc((d.tbs_size-nvl(s.free_space, 0))*100/d.tbs_maxsize)) kperc
    FROM (
    SELECT SUM(bytes) tbs_size, SUM(decode(sign(maxbytes - bytes), -1, bytes, maxbytes)) tbs_maxsize, tablespace_name tablespace
    FROM (
SELECT nvl(bytes, 0) bytes, nvl(maxbytes, 0) maxbytes, tablespace_name FROM dba_data_files
UNION ALL
SELECT nvl(bytes, 0) bytes, nvl(maxbytes, 0) maxbytes, tablespace_name FROM dba_temp_files
    )
GROUP BY tablespace_name
    ) d, (SELECT SUM(bytes) free_space, tablespace_name tablespace FROM dba_free_space GROUP BY tablespace_name) s, dba_tablespaces t
  WHERE t.tablespace_name = d.tablespace(+) AND
t.tablespace_name = s.tablespace(+)
  ORDER BY 8)
  WHERE kperc > 93
  AND tipo <>'T'
  AND tipo <>'U';
  
--userconn=查询数据库当前连接数，整数，单位：个
SELECT count(username) FROM v$session WHERE username IS NOT NULL;

--waits_controfileio=控制文件写等待，整数，单位：ms waits/s
SELECT sum(decode(event,'control file sequential read', total_waits, 'control file single write', total_waits, 'control file parallel write',total_waits,0)) ControlFileIO FROM V$system_event WHERE 1=1 AND event NOT IN ( 'SQL*Net message from client', 'SQL*Net more data from client','pmon timer', 'rdbms ipc message', 'rdbms ipc reply', 'smon timer');

--waits_directpath_read=直接路径写等待，整数，单位：ms waits/s
SELECT sum(decode(event,'direct path read',total_waits,0)) DirectPathRead FROM V$system_event WHERE 1=1 AND event NOT IN ('SQL*Net message from ', 'SQL*Net more data from client','pmon timer', 'rdbms ipc message', 'rdbms ipc reply', 'smon timer');

--waits_file_io=IO读写文件等待，整数，单位：ms waits/s
SELECT sum(decode(event,'file identify',total_waits, 'file open',total_waits,0)) FileIO FROM V$system_event WHERE 1=1 AND event NOT IN ('SQL*Net message from client',   'SQL*Net more data from client', 'pmon timer', 'rdbms ipc message', 'rdbms ipc reply', 'smon timer');

--Latch 是一种低级排队(串行)机制,用于保护 SGA 中共享内存结构。
--Latch 是一种快速的被获取和释放的内存锁,用于防止共享内存结构被多个用户同时访问。
--waits_latch=latch（低级排行机制）等待，整数，单位：ms waits/s
SELECT sum(decode(event,'control file sequential read', 
    total_waits, 'control file single write', total_waits, 'control file parallel write',total_waits,0)
) ControlFileIO
FROM V$system_event WHERE 1=1 AND event NOT IN (
  'SQL*Net message from client',
  'SQL*Net more data from client',
  'pmon timer', 'rdbms ipc message',
  'rdbms ipc reply', 'smon timer');


--waits_logwrite=日志文件写等待，整数，单位：ms waits/s
SELECT sum(decode(event,'log file single write',total_waits, 'log file parallel write',total_waits,0)) LogWrite
FROM V$system_event WHERE 1=1 AND event NOT IN (
  'SQL*Net message from client',
  'SQL*Net more data from client',
  'pmon timer', 'rdbms ipc message',
  'rdbms ipc reply', 'smon timer');

--用来约束Oracle进行多数据块读取
--waits_multiblock_read=数据文件离散读等待，整数，单位：ms waits/s
SELECT sum(decode(event,'db file scattered read',total_waits,0)) MultiBlockRead
FROM V$system_event WHERE 1=1 AND event NOT IN (
  'SQL*Net message from client',
  'SQL*Net more data from client',
  'pmon timer', 'rdbms ipc message',
  'rdbms ipc reply', 'smon timer');

--waits_other=其它等待，整数，单位：ms waits/s
SELECT sum(decode(event,'control file sequential read',0,'control file single write',0,'control file parallel write',0,'db file sequential read',0,'db file scattered read',0,'direct path read',0,'file identify',0,'file open',0,'SQL*Net message to client',0,'SQL*Net message to dblink',0, 'SQL*Net more data to client',0,'SQL*Net more data to dblink',0, 'SQL*Net break/reset to client',0,'SQL*Net break/reset to dblink',0, 'log file single write',0,'log file parallel write',0,total_waits)
) 
Other FROM V$system_event WHERE 1=1 AND event NOT IN ('SQL*Net message from client', 'SQL*Net more data from client', 'pmon timer', 'rdbms ipc message',  'rdbms ipc reply', 'smon timer');

--waits_singleblock_read=数据文件顺序读等待，整数，单位：ms waits/s
SELECT sum(decode(event,'db file sequential read',total_waits,0)) SingleBlockRead 
FROM V$system_event WHERE 1=1 AND event NOT IN (
    'SQL*Net message from client',
    'SQL*Net more data from client',
    'pmon timer', 'rdbms ipc message',
    'rdbms ipc reply', 'smon timer');

--waits_sqlnet=监视节点上的侦听器等待，整数，单位：ms waits/s
SELECT sum(decode(event,'SQL*Net message to client',total_waits,'SQL*Net message to dblink',total_waits,'SQL*Net more data to client',total_waits,'SQL*Net more data to dblink',total_waits,'SQL*Net break/reset to client',total_waits,'SQL*Net break/reset to dblink',total_waits,0)) 
SQLNET FROM V$system_event WHERE 1=1
AND event NOT IN ( 'SQL*Net message from client','SQL*Net more data from client','pmon timer','rdbms ipc message','rdbms ipc reply', 'smon timer');

--dg_error=归档日志错误信息，字符串
SELECT ERROR_CODE, SEVERITY, MESSAGE, TIMESTAMP, 'DD-MON-RR HH24:MI:SS' TIMESTAMP FROM V$DATAGUARD_STATUS WHERE CALLOUT='YES' AND TIMESTAMP > SYSDATE-1
--归档日志错误数，整数
select count(error) from v$archive_dest_status;

--dg_sequence_number=归档日志历史最大序列号，整数
SELECT MAX (sequence#) FROM v$log_history;

--dg_sequence_number_stby=归档日志最大重做系列号，整数
SELECT max(sequence#) FROM v$archived_log;

--instance_status=查询当前实例的状态，字符串
SELECT status FROM v$instance;

--database_status=查询数据库开放模式（读写）状态，字符串
SELECT open_mode FROM v$database;
