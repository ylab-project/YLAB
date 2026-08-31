function msg = get_exitflag_description(exitflag)
%get_exitflag_description - 終了状態の説明文を返す
%
%   msg = get_exitflag_description(exitflag) は、指定された終了状態の
%   説明文を返す。
%
%   入力引数:
%     exitflag - 終了状態
%
%   出力引数:
%     msg - 説明文字列

switch exitflag
  case PRM.EXITFLAG_NO_FEASIBLE
    msg = '許容解が見つかりませんでした';
  case PRM.EXITFLAG_TIMEOUT
    msg = '時間制限に到達しました';
  case PRM.EXITFLAG_USER_STOP
    msg = 'ユーザーにより中断されました';
  case PRM.EXITFLAG_FILE_ERROR
    msg = 'ファイルI/Oエラーが発生しました';
  case PRM.EXITFLAG_INPUT_ERROR
    msg = '入力データにエラーがあります';
  case PRM.EXITFLAG_LIST_ERROR
    msg = 'リストデータに関するエラーが発生しました';
  case PRM.EXITFLAG_ENV_ERROR
    msg = '実行環境のエラーが発生しました';
  case PRM.EXITFLAG_LICENSE_ERROR
    msg = 'ライセンス有効期限が終了しました';
  case PRM.EXITFLAG_INTERNAL_ERROR
    msg = '予期しないエラーが発生しました';
  otherwise
    msg = '不明なエラーが発生しました';
end

return
end
