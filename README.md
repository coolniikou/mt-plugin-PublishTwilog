#About the PublishTwilog plugin for Movable Type
PublishTwilog is a plugin for Movable Type provides tweet data from Twilog(web-service : http://twilog.org/);.  

PublishTwilog pluginは、Twilogサービスから昨日（１日分）のTweetデータを取得し、エントリーとして自動で記事投稿します。  
定期(毎日)にスケジュールタスク(\*1)実行設定することで昨日のTweetを自動投稿できるようになります。


####\*1スケジュールタスクの実行
- cron等で定期で$MT_HOME/tools/run-periodic-tasksを実行する(linux or Unix)  
- タスク・スケジューラで$MT_HOME/tools/run-periodic-tasksを実行する(windows)  
- ログフィードを定期的に取得するようにする(	フィードリーダ等で定期的に読み込むように設定する)  
- XML-RPCのAPI、mt.runPeriodicTasksを定期的に利用する  



##PublishTwilogプラグイン インストール・設定までの流れ   
 1. プラグインフォルダ($MT_HOME/plugin)にPublishTwilogフォルダを追加。  
 2. tweet専用カテゴリ作成（再構築後にカテゴリIDを確認・記録）  
 3. プラグインページにて必要情報を設定。（Twitterユーザーネーム、投稿ブログID、投稿者ID、カテゴリID、公開ステータス（一般公開は１）エントリータイトル） 

 3. テスト確認：システムログページに移り、ログフィードリンクをクリックすることでフィードを読み込む。（＝スケジュールタスクが実行される） 
 4. スケジュールタスク実行の設定を行う。


追加されるテンプレートタグ等はございません。  

###更新履歴
 - 2011/5/23 PublishTwilog プラグイン git リポジトリアップ
	前バージョンからの変更点: twilogデータ取得パターンの変更 
