function [gphead, gpbody] = write_cell_girder_property(com, result)
%write_cell_girder_property - 梁断面諸量出力のセル配列を生成
%
%   [gphead, gpbody] = write_cell_girder_property(com, result) は、
%   梁断面の諸量（E, G, Io, I, As, An, α, β, κ, 部材長, 剛域,
%   フェイス位置, 結合状態 等）を符号ごとに集計したセル配列を
%   生成する。Kブレース通し梁は左右ペアを1行にまとめて出力する。
%
%   入力引数:
%     com    - 共通オブジェクト
%     result - 解析結果構造体 (msprop, Iy, gphiI 等)
%
%   出力引数:
%     gphead - ヘッダ部セル配列 [3×19]
%     gpbody - データ部セル配列 [(2*nrow)×20]（最終列は CONT_MARKER）

% 定数
ng = com.nmeg;
nstory = com.nstory;

% 共通配列
girder = com.member.girder;
secg = com.section.girder;
msprop = result.msprop;
Iy = result.Iy;
gphiI = result.gphiI;
gphiAs = result.gphiAs;
gphiAn = result.gphiAn;
lm = result.lm;
lfg = result.lf.girder;
lrg = result.lr.girder;

% 準備計算
Em = msprop.E;
Gm = msprop.G;

% --- 梁断面 ---
gphead = {'層', 'ﾌﾚｰﾑ', '軸－軸', '', '符号', 'E', 'Io', 'φI', ...
  'I', 'Aso', 'φQ', 'As', 'α', 'β', '部材長', '剛域', 'ﾌｪｲｽ', ...
  'ﾊﾟﾈﾙ', '結合';
  '', '', '', '', '', 'G', '', '', '', 'Ano', 'φn', 'An', ...
  'αn', 'κ', '', '左/右', '左/右', '左/右', '左/右';
  '', '', '', '', '', 'kN/mm2', 'cm4', '', 'cm4', 'cm2', '', ...
  'cm2', '', '', 'mm', 'mm', 'mm', 'mm', ''};
gpbody = cell(ng*2, size(gphead,2)+1);  % 末尾は marker 列
irow = 0;
for i=1:nstory
  ist = nstory-i+1;
  for ig = 1:ng
    if girder.idstory(ig)~=ist
      continue
    end
    gtype = girder.type(ig);
    if gtype == PRM.GIRDER_FOR_KBRACE2
      continue
    end
    if gtype == PRM.GIRDER_FOR_KBRACE1
      ig_pair = girder.idconnected_girder(ig);
    else
      ig_pair = 0;
    end
    irow = irow+1;
    write_gp_entry(ig, ig_pair);
    % 1 梁 = 2 物理行/論理ブロック。1 行目に CONT_MARKER
    gpbody{irow*2-1, end} = PRM.CONT_MARKER;
  end
end

return

  function write_gp_entry(ig_left, ig_right)
  %write_gp_entry - 梁1組（左右ペアまたは単独）を gpbody に出力
  %
  %   write_gp_entry(ig_left, ig_right) は、左右の梁番号を受け
  %   gpbody の現在 irow 位置に左端／右端情報と部材長を書き出す。
  %   ig_right<=0 の場合は単独梁として ig_left を両端に用いる。
  %
  %   入力引数:
  %     ig_left  - 左端側の梁部材番号（スカラー）
  %     ig_right - 右端側の梁部材番号（0以下なら単独扱い）
  %
  %   出力引数:
  %     なし（外側の gpbody を更新）
    if ig_right <= 0
      ig_right = ig_left;
    end
    write_gp_left(irow, ig_left);
    write_gp_right(irow, ig_right);
    % 部材長。K形分割の左右ペアは合計が分割前の梁長になる。
    % 名目梁は通し梁指定でさらに連結されうるため使わない
    lg_ = lm(girder.idme(ig_left));
    if ig_right ~= ig_left
      lg_ = lg_ + lm(girder.idme(ig_right));
    end
    gpbody{irow*2-1,15} = sprintf('%.0f', lg_);
  end

  function write_gp_left(irow_, ig_)
  %write_gp_left - 梁の左端側情報を gpbody の指定行に書き出す
  %
  %   write_gp_left(irow_, ig_) は、論理ブロックの 1 物理行目
  %   (gpbody{irow_*2-1, :}) に梁 ig_ の左端側情報を書き込む。
  %
  %   入力引数:
  %     irow_ - 論理ブロックの行番号（1始まり）
  %     ig_   - 対象梁部材番号
  %
  %   出力引数:
  %     なし（外側の gpbody を更新）
    idm_ = girder.idme(ig_);
    gpbody{irow_*2-1,1} = girder.story_name{ig_};
    gpbody{irow_*2-1,2} = girder.frame_name{ig_};
    gpbody{irow_*2-1,3} = girder.coord_name{ig_,1};
    gpbody{irow_*2-1,4} = '';
    idsec_ = girder.idsecg(ig_);
    gpbody{irow_*2-1,5} = make_section_symbol(secg, idsec_);
    gpbody{irow_*2-1,6} = sprintf('%.1f', Em(idm_)*1.d-3);
    gpbody{irow_*2-1,7} = fmt_adaptive(msprop.Iy(idm_)*1.d-4);
    gpbody{irow_*2-1,8} = sprintf('%.3f', gphiI(ig_));
    gpbody{irow_*2-1,9} = fmt_adaptive(Iy(idm_)*1.d-4);
    gpbody{irow_*2-1,10} = fmt_adaptive(msprop.Asy(idm_)*1.d-2);
    gpbody{irow_*2-1,11} = sprintf('%.3f', gphiAs(ig_));
    gpbody{irow_*2-1,12} = fmt_adaptive(...
      msprop.Asy(idm_) * gphiAs(ig_) * 1.d-2);
    gpbody{irow_*2-1,13} = 1;
    gpbody{irow_*2-1,14} = 1;
    gpbody{irow_*2-1,16} = sprintf('%.0f', lrg(ig_,1));
    gpbody{irow_*2-1,17} = sprintf('%.0f', lfg(ig_,1));
    gpbody{irow_*2-1,19} = joint_label(girder.joint(ig_,1));
  end

  function write_gp_right(irow_, ig_)
  %write_gp_right - 梁の右端側情報を gpbody の指定行に書き出す
  %
  %   write_gp_right(irow_, ig_) は、論理ブロックの 1 物理行目末尾
  %   (4列) と 2 物理行目 (gpbody{irow_*2, :}) に梁 ig_ の右端側
  %   情報を書き込む。
  %
  %   入力引数:
  %     irow_ - 論理ブロックの行番号（1始まり）
  %     ig_   - 対象梁部材番号
  %
  %   出力引数:
  %     なし（外側の gpbody を更新）
    idm_ = girder.idme(ig_);
    gpbody{irow_*2-1,4} = girder.coord_name{ig_,2};
    gpbody{irow_*2,6} = sprintf('%.2f', Gm(idm_)*1.d-3);
    Ano_ = msprop.A(idm_) * 1.d-2;
    gpbody{irow_*2,10} = fmt_adaptive(Ano_);
    gpbody{irow_*2,11} = sprintf('%.3f', gphiAn(ig_));
    gpbody{irow_*2,12} = fmt_adaptive(Ano_ * gphiAn(ig_));
    gpbody{irow_*2,13} = 1;
    kappa_ = get_kappa(secg.type(girder.idsecg(ig_)));
    gpbody{irow_*2,14} = kappa_;
    gpbody{irow_*2,16} = sprintf('%.0f', lrg(ig_,2));
    gpbody{irow_*2,17} = sprintf('%.0f', lfg(ig_,2));
    gpbody{irow_*2,19} = joint_label(girder.joint(ig_,2));
  end

  function label = joint_label(value)
  %joint_label - 結合状態コードから表示文字列に変換
  %
  %   label = joint_label(value) は、結合状態コード（PRM.PIN/FIX）
  %   を表示文字列（"ピン"/"剛接"）に変換する。該当しない場合は
  %   空文字を返す。
  %
  %   入力引数:
  %     value - 結合状態コード（PRM.PIN, PRM.FIX 等）
  %
  %   出力引数:
  %     label - 表示文字列
    switch value
      case PRM.PIN
        label = "ピン";
      case PRM.FIX
        label = "剛接";
      otherwise
        label = "";
    end
  end

  function kappa = get_kappa(stype)
  %get_kappa - 断面種別に応じたせん断形状係数を返す
  %
  %   kappa = get_kappa(stype) は、断面種別 stype に応じて
  %   せん断形状係数 κ を返す。RC矩形断面（PRM.RCRS）は 1.2、
  %   それ以外は 1 を返す。
  %
  %   入力引数:
  %     stype - 断面種別コード
  %
  %   出力引数:
  %     kappa - せん断形状係数
    if stype == PRM.RCRS
      kappa = 1.2;
    else
      kappa = 1;
    end

    return
  end

  function s = fmt_adaptive(v)
  %fmt_adaptive - SS7 互換の適応桁数フォーマット
  %
  %   s = fmt_adaptive(v) は、数値 v を SS7 互換の桁数で書式化
  %   する。|v| >= 1000 のとき整数表示、未満のとき小数2桁とする。
  %
  %   入力引数:
  %     v - 数値
  %
  %   出力引数:
  %     s - 書式化文字列
    if abs(v) >= 1000
      s = sprintf('%.0f', v);
    else
      s = sprintf('%.2f', v);
    end

    return
  end
end

