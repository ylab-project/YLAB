function [ar, ignored] = clear_pinjoint_end_moments(ar0, joint)
%clear_pinjoint_end_moments - ピン端固定端モーメントを0にする
%
%   [ar, ignored] = clear_pinjoint_end_moments(ar0, joint) は、
%   部材端結合条件がピンの局所Y・Z軸回り固定端モーメントを、
%   全荷重ケースについて0にする。除外前の値はignoredへ保存する。
%
%   入力引数:
%     ar0   - 変更前の部材固定端力 [nme x 12 x nlc]
%     joint - 部材端結合条件 [nme x 4]
%
%   出力引数:
%     ar      - ピン端固定端モーメントを0にした配列
%     ignored - 0にした固定端モーメント [nme x 12 x nlc]
%
%   備考:
%     - 除外したモーメントの他端・せん断力への再配分は行わない。

joint_columns = [1 2 3 4];
force_columns = [5 11 6 12];
ar = ar0;
ignored = zeros(size(ar0));
for ipair = 1:length(joint_columns)
  ispin = joint(:,joint_columns(ipair)) == PRM.PIN;
  if ~any(ispin)
    continue
  end
  force_column = force_columns(ipair);
  ignored(ispin,force_column,:) = ar0(ispin,force_column,:);
  ar(ispin,force_column,:) = 0;
end

return
end
