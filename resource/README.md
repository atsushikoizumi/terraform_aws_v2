# module resource
AWS の各リソースを管理する module です。<br>
各リソースのパラメータを編集する場合は、本階層の .tf ファイルを編集してください。

# lambda ソースの準備方法
以下の手順にて、lambda 用のライブラリを準備します。<br>
  ```
  1. ディレクトリ（resource）に移動
    
    cd ~/.../resource
    
  2. python ライブラリ保存用ディレクトリ作成
    
    mkdir -p build/resource_stop/layer/python
    
  3. ライブラリのインストール
    
    python3 -m pip install boto3    -t build/resource_stop/layer/python
    python3 -m pip install datetime -t build/resource_stop/layer/python
    
  4. キャッシュ系ファイルの削除（不要な差分発生を回避するため）
    
    find build -type f | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm
  ``` 

以上です。