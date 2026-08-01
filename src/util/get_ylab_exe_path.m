function path = get_ylab_exe_path()
%get_ylab_exe_path - 実行中の YLAB.exe のフルパスを取得する
%
%   path = get_ylab_exe_path() は、現在のWindowsプロセスが実行して
%   いるEXEのフルパスを返す。配布実行時に呼ぶため、対象は起動された
%   YLAB.exe である。
%
%   出力引数:
%     path - 実行中のEXEのフルパス
%
%   備考:
%     - MATLAB実行時に呼ぶと MATLAB.exe のパスが返るため、
%       MCC／配布実行の分岐からのみ呼ぶ。
%     - System.Diagnostics.Process は既定でロードされる .NET
%       アセンブリに含まれ、NET.addAssembly の呼び出しは不要。

process = System.Diagnostics.Process.GetCurrentProcess();
path = char(process.MainModule.FileName);

return
end
