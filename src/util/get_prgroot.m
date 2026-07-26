function path = get_prgroot()
%GET_PRGROOT プログラムのインストールルートディレクトリを取得する
%
%   path = get_prgroot()
%
%   Output:
%       path - 標準インストールパス
%              (例: "C:\Program Files\YLAB\YLAB\application")

    path = fullfile(getenv("ProgramFiles"),'YLAB','YLAB','application');
end
