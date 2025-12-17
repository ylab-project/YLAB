function path = get_prgroot()
%GET_PRGROOT プログラムのインストールルートディレクトリを取得する
%
%   path = get_prgroot()
%
%   Output:
%       path - 標準インストールパス (例: "C:\Program Files\TUS\YLAB\application")

    path = fullfile(getenv("ProgramFiles"),'TUS','YLAB','application');
end
