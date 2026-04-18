function [ipos, type_label] = ...
  resolve_brace_position_label(brace, ib, ij, npair)
%resolve_brace_position_label - ブレースの物理位置と表示ラベルを決定
%
%   [ipos, type_label] = resolve_brace_position_label(brace, ib, ij, npair)
%   は、ブレース部材 ib の形状・ペア属性から物理位置 ipos と表示ラベル
%   type_label を返す。
%
%   入力引数:
%     brace - ブレース部材テーブル（type, pair, idpair を参照）
%     ib    - ブレース部材インデックス
%     ij    - idmeb 上の列番号（1:左 / 2:右）。K形の物理位置として使用
%     npair - nominal ブレース内の部材数（1:単独 / 2:ペア）
%
%   出力引数:
%     ipos       - 物理位置（1:左 / 2:右）
%     type_label - 表示ラベル（'／','＼','Ｘ','K上','K上／','K上＼',
%                  'K下','K下／','K下＼' のいずれか）

switch brace.type(ib)
  case PRM.BRACE_MEMBER_TYPE_X
    % X形: pair属性（左／右）で物理位置を決定
    if brace.pair(ib) == PRM.BRACE_MEMBER_PAIR_L
      ipos = 1;
    else
      ipos = 2;
    end
    % idpair が自身を指さない場合はペアでX、単独なら傾き方向で表示
    if brace.idpair(ib) ~= ib
      type_label = 'Ｘ';
    elseif ipos == 1
      type_label = '／';
    else
      type_label = '＼';
    end
  case PRM.BRACE_MEMBER_TYPE_K_UPPER
    % K形（上向き）: 物理位置は idmeb の列番号（ij）をそのまま使用
    % npair==1（単独）時は傾き方向記号を付加
    ipos = ij;
    if npair == 1 && ipos == 1
      type_label = 'K上／';
    elseif npair == 1 && ipos == 2
      type_label = 'K上＼';
    else
      type_label = 'K上';
    end
  case PRM.BRACE_MEMBER_TYPE_K_LOWER
    % K形（下向き）: 同上
    ipos = ij;
    if npair == 1 && ipos == 1
      type_label = 'K下／';
    elseif npair == 1 && ipos == 2
      type_label = 'K下＼';
    else
      type_label = 'K下';
    end
end

return
end
