function validateargs(options)
%VALIDATEARGS オプションの検証を行う
%
%   validateargs(options)
%
%   入力:
%       options - CommonOption オブジェクト
%
%   説明:
%       CommonOption クラスの validate メソッドを呼び出し、必須パラメータ
%       (inputfile, outputfile 等) の設定状況を確認する。
%       検証に失敗した場合はエラー 'YLAB:InvalidOptions' を送出する。

try
    options.validate();
catch ME
    error('YLAB:InvalidOptions', ...
        'オプション値の検証に失敗しました: %s', ME.message);
end
end
