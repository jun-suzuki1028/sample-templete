###### tags: `AWS` `SQS` `SNS` `VPC` `EC2` `RDS`
 
# classmethod作業手順書

## 実行環境
* Windows 10 Home
* AWS CLI

## フォルダ構成

```
.
├── 作業手順書.md　#
├── 作業手順書.html
└── task
    ├── 01_network.bat
    ├── 02_security.bat
    ├── 03_web.bat
    ├── 04_rds.bat
    ├── 05_endpoint.bat
    └── templete
        ├── network.yml
        ├── security.yml
        ├── web.yml
        ├── rds.yml
        └── endpoint.yml


```


## 構成
与えられた課題に加え、以下のテーマで作成
* セキュアな構成するため、サーバーはプライベートサブネットに配置
* Cloudformationを使用した自動化
    * 使いまわしができるよう、パラメーターはなるべく可変


### 構成図
![](https://i.imgur.com/fyQBO9y.png)


***

## 作業手順
1. IAMユーザー作成
2. Cloudformationによるインフラ構築(課題1)
3. 動作確認(課題1)
4. Cloudformationによるインフラ構築(課題2)
5. CPU使用率出力用スクリプト作成/実行(課題2)
6. CPU使用率取得用スクリプト作成/実行(課題2)

### 1. IAMユーザー作成

* Cloudformationの実行をAWS CLIを使用するため、IAMユーザー作成時にアクセスキー、シークレットアクセスキーを発行(コンソール操作)

* 取得したアクセスキー、シークレットアクセスキーをAWS CLIのプロファイルに設定する。

    * 以下のコマンドをターミナルで実行
    `AWS configure --profile testuser`
    
    * アクセスキー、シークレットアクセスキー、リージョンを順番に入力(今回は東京リージョンで作成)



### 2. Cloudformationによるインフラ構築(課題1)

Cloudformationの実行はパラメーターの入力を簡単にするため、AWS CLIのコマンドをbatファイル化。

batファイルは以下の順序で実行。
(03,04,05は並列で実行可能)

1. 01_network.bat
2. 02_security.bat
3. 03_web.bat　**※AWS SNSで通知先のメールアドレスを確認すること**
4. 04_rds.bat
5. 05_endpoint.bat

全て正常に終了したことをコンソールから確認すること。

### 3 動作確認

#### 3.1 Webサーバーログイン
Webサーバー(EC2)にSystems Managerのセッションマネージャーを使用して作業を実施する。

1. マネージメントコンソールのEC2からログインしたいものを選択。
2. 接続ボタンから「セッションマネージャー」を選択して接続
3. 正常にコマンドラインが表示されることを確認

#### 3.2 データべース接続
上記で接続したWebサーバーからデータベース(RDS)のMySQLにアクセスできることを確認する。

1. RDSのエンドポイントを確認
マネージメントコンソールからRDSのエンドポイントを確認する。

2. MySQLへログイン
ユーザー名はRDS作成時に入力したもの、エンドポイントは1.で確認したものを書き換える
`mysql -u 【ユーザー名】 -p -h 【エンドポイント】`

3. パスワードを入力 
`Enter password:` と表示されるため、RDS作成時に決めたものを入力

4. 以下のようなメッセージが表示されることを確認

```bash
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 6
Server version: 5.7.26-log Source distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]>
```

#### 3.3 データベースの内容を表示(時間があれば)

1. 以下のコマンドでテーブル、データを作成
```bash
$ create database testdb;
$ create table testdb.user(id int , name varchar(20));
$ insert into testdb.user VALUES (1,'tanaka'),(2,'satou');
```

2. 正常に作成されたことを確認

```bash
$ select * from testdb.user;
```

3. 拡張子が.phpのファイルがphpファイルとして読み込まれるように設定

```bash
$ sudo vi /etc/httpd/conf/httpd.conf
```

```bash
<IfModule mime_module>
・・・(略)
AddType application/x-httpd-php .php //←追加
</IfModule>
```

4. Apacheを再起動
```bash
$ sudo service httpd restart
```

5. phpファイル作成

```bash
$ sudo vi /var/www/html/index.php
```
```php
<?php
try
{
$dbs = "mysql:host=【エンドポイント】;dbname=testdb;charset=utf8";
$user='【ユーザー名】';
$password='【パスワード】';
$dbh=new PDO($dbs, $user, $password);
$dbh->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$sql='SELECT * FROM user';
$stmt=$dbh->prepare($sql);

$dbh=null;
//実行
$stmt->execute();

$all = $stmt->fetchAll();
//配列を表示
foreach($all as $loop){
  echo $loop['id']." ".$loop['name'].'<br>';
}

}
catch (Exception $e)
{
        print '接続失敗';
        exit();
}
?>
```

6. ALBのDNSでアクセス
データベースに入力した値が表示されるかを確認

***

### 4 Cloudformationによるインフラ構築(課題2)

AWS SQS,AWS SNSをCloudformationで作成。
課題1で実行した`03_web.bat`でSNS,SQS作成済みのためスキップ。

### 5. CPU使用率出力用スクリプト作成/実行(課題2)

AWS SNSに対して、CPU使用率を送付するためのシェルスクリプトを作成、実行する。

1. webサーバー1に対してログイン
2. 以下のコマンドを実行

```bash
$ sudo su
$ mkdir /bin/script-sns
$ cd /bin/script-sns
```

3. aws configureでリージョンを指定
```
$ aws configure
```

4. `vi sns-push.sh`で以下のシェルスクリプトを作成
```bash
#!/bin/bash

########################################################
# CPU使用率監視シェル
#
#  機能  ：CPU使用率をインターバル間隔で取得し、
#          現在のCPU使用率をSNSに送信する。
#  引数  ：なし
#
########################################################

# 変数初期値代入
INTERBAL=60    #監視間隔(秒)
SNSTOPIC="【SNSトピックARN】"    #SNSトピックARN
# メイン処理
while true
do
    # CPUのアイドル値を取得
    VMSTAT=`vmstat 1 2 | tail -1`
    US=`echo ${VMSTAT} | awk '{print $13}'`
    SY=`echo ${VMSTAT} | awk '{print $14}'`
    TOTAL=$((US+SY))
    # CPUの使用率を計算
    DATE=`TZ=JST-9 date "+%Y/%m/%d-%H:%M:%S"`

    OUTPUT="${DATE}-現在のCPU使用率は${TOTAL}%です。"
    echo ${OUTPUT}
    echo ${OUTPUT}　>> publishOutput.txt
    aws sns publish --topic-arn ${SNSTOPIC} --message ${OUTPUT}
    sleep ${INTERBAL}
    
# エラーハンドリング…

done
```

5. 実行して正常に以下のようなメッセージが出力されるか確認
```bash
2020/03/12-15:13:23-現在のCPU使用率は0%です。
{
    "MessageId": "95aa2ba9-ded2-5a83-a352-7d4a0b9657ba"
}
```


### 6. CPU使用率確認用シェルスクリプト作成/実行(課題2)


AWS SNSに対して、CPU使用率を送付するためのシェルスクリプトを作成、実行する。

1. webサーバー2に対してログイン
2. 以下のコマンドを実行。

```bash
$ sudo su
$ mkdir /bin/script-sqs
$ cd /bin/script-sqs
```

3. aws configureでリージョンを指定
```
$ aws configure
```

4. `vi sqs-receive.sh`で以下のシェルスクリプトを作成
```bash
#!/bin/bash

########################################################
# CPU使用率取得シェル
#
#  機能  ：SQSキューをインターバル間隔で取得し、
#          コマンドライン上に表示する。
#  引数  ：なし
#
########################################################

# 変数初期値代入
INTERBAL=10    #取得間隔(秒)
SQS_QUEUE_URL="【SQSキューURL】"    #SQSキューURL
SQS_RECEIPT_HANDLE=""
SQS_MESSAGE=""
JSON={}
# メイン処理
while true
do
    # キューメッセージの取得
    JSON=`aws sqs receive-message --queue-url ${SQS_QUEUE_URL}`
    SQS_BODY=`echo ${JSON} | jq '.Messages[]'`

    if [ -n "$SQS_BODY" ]; then
        echo ${SQS_BODY}
        echo ${SQS_BODY} >> ./receiveOutput.txt
        # 取得したキューメッセージを削除
        SQS_RECEIPT_HANDLE=`echo ${JSON} | jq -r '.Messages[].ReceiptHandle'`
        aws sqs delete-message --queue-url ${SQS_QUEUE_URL} --receipt-handle ${SQS_RECEIPT_HANDLE}
    fi

    sleep ${INTERBAL}

done


```

5. 実行してエラーメッセージが出ないかを確認