# このプラグインは

Movable Typeのテンプレートで、JSONなどの構造体フォーマットを出力する処理をサポートします。

# 使い方

    <mtsf:Hash format="json">
      <mt:EntryTitle as="title">
      <mt:EntryBody as="body">
      <mtsf:Array as="categories">
        <mt:EntryCategories>
          <mt:CategoryLabel as="__value__">
        </mt:EntryCategories>
      </mtsf:Array>
    </mtsf:Hash>


# タグとモディファイア

## `mtsf:*`タグに共通のモディファイア

### `set_as` モディファイア

値を保存する変数名を指定します。

タグが`mtsf:Hash`の子要素の場合は、親要素に追加するキー名になります。

タグが`mtsf:Array`の子要素の場合は、特に使用されず無視されます(配列にキー名は不要のため)。

### `format` モディファイア

出力するフォーマットを選択できます。

* `json` JSON形式
* `yaml` YAML形式

## `mtsf:Hash` (または `mtsf:Object`) ブロックタグ

ハッシュ形式の値を作成します。

## `mtsf:Array` ブロックタグ

配列形式の値を作成します。

## `mtsf:Value` (または `mtsf:Scalar`) ブロックタグ

テンプレート内部の値を変数に格納します。

`mtsf:Hash`や`mtsf:Array`が親要素にある場合は、その子要素に追加されます。

## `mtsf:Var`

テンプレート変数に格納されたハッシュや配列を`format`モディファイアで指定したフォーマットで整形して出力します。

このタグでは、共通の`set_as`モディファイアは使用できません。

### `name` モディファイア

出力する値が格納された変数名を指定します。

## グローバルモディファイア

### `set_as` モディファイア

任意のタグに指定することにより、`mtsf:Value`と同じように、タグの出力結果を変数に格納します。

# 拡張

## 出力フォーマット

他の任意のプラグインで出力フォーマットを拡張することができます。

例えば次のプラグインは、`mtsf:*`テンプレートタグの`format`属性に、PHP独自のシリアライズ記法で出力する`php`を指定できるようにします。

### config.yaml

    id: StructureFormatPHPSerialize
    version: 1.0.0
    structure_formats:
        php:
            dump: |
                sub {
                    my ( $value, $args ) = @_;
                    require 'PHP::Serialization';
                    PHP::Serialization->encode($value);
                }
            load: |
                sub {
                    my ( $value, $args ) = @_;
                    require 'PHP::Serialization';
                    PHP::Serialization->decode($value);
                }
