在 MySQL 8.0 中，授权用户远程连接需要使用 GRANT 命令。下面是详细的步骤：

首先，在 MySQL 中创建具有远程连接权限的用户。在 MySQL 命令行中执行以下命令：

CREATE USER 'remote_user'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
将 'remote_user' 替换为您要使用的用户名，将 'password' 替换为该用户的密码。

授予该用户连接到所有数据库的权限。在 MySQL 命令行中执行以下命令：

GRANT ALL PRIVILEGES ON *.* TO 'remote_user'@'%';
如果您只希望授予该用户连接到特定数据库的权限，请使用以下命令：

GRANT ALL PRIVILEGES ON dbname.* TO 'remote_user'@'%';
将 'dbname' 替换为要授权访问的数据库名。

执行以下命令以使更改生效：

FLUSH PRIVILEGES;