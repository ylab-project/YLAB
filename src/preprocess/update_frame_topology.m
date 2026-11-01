function com = update_frame_topology(com)
%update_frame_topology - 現在の節点・部材接続から解析用の対応を更新する
%
%   com = update_frame_topology(com) は、自由度、名目部材、断面から
%   部材への対応と端部・補剛の接続を生成する。初回と分割構成変更時に
%   呼び、固定した変数・代表断面・断面管理と入力荷重は変更しない。
%
%   入力引数:
%     com - 現在の節点、部材、入力定義を持つ共通データ
%
%   出力引数:
%     com - 現在の接続に整合する自由度と対応関係を持つ共通データ

%% 節点自由度の数え上げ
[com.node.dof, com.node.ind, com.story.idnoderep, com.node.xr, ...
  com.node.yr, com.ndf, com.idf2node, com.story.isrigid] = ...
  countup_node2df(com);

%% 共通配列
member_girder = com.member.girder;
member_column = com.member.column;
member_brace = com.member.brace;
member_horizontal_brace = com.member.horizontal_brace;

node_std = com.node;
node_std.z = node_std.z_standard;
[com.member.property.cxl, com.member.property.cyl] = ...
  update_member_cosine(member_girder, member_column, ...
  member_brace, member_horizontal_brace, node_std);

girder_idnode1 = member_girder.idnode1;
girder_idnode2 = member_girder.idnode2;
girder_dx = node_std.x(girder_idnode2) - node_std.x(girder_idnode1);
girder_dy = node_std.y(girder_idnode2) - node_std.y(girder_idnode1);
[member_girder.isxdir, member_girder.isydir] = ...
  classify_girder_xy_direction(girder_dx, girder_dy);
com.member.girder = member_girder;
com.node.is_roof = countup_node_is_roof(com);
% 部材が跨ぐ階は断面寸法に依存しない幾何判定なので前処理で確定する
com.member.property.idfloor = countup_member_floor(com);

%% バンド幅算定
nbw = countup_band_width(com);
com.nbw = nbw;

%% 通し柱
[idnominal_column, idsecc, nominal_column] = ...
  countup_nominal_column(member_column, member_girder, member_brace, com);
member_column.idnominal = idnominal_column;
member_column.idsecc = idsecc;
idsec = com.section.column.idsec(idsecc);
% isthrough/idconnected は countup でのみ使用。下流へ持ち越さない
member_column = rmfield(member_column, {'isthrough', 'idconnected'});
com.member.column = member_column;
com.member.property.idsec(member_column.idme) = idsec;
com.member.property.idsecc(member_column.idme) = idsecc;
com.nominal.column = nominal_column;
com.num.nominal_column = nnz(idnominal_column(:,2)==1);

%% 柱の方向別基礎梁接続フラグ
col_in1 = member_column.idnode1;
gir_in1 = member_girder.idnode1;
gir_in2 = member_girder.idnode2;
gir_isxdir = member_girder.isxdir;
gir_isydir = member_girder.isydir;
gir_isfg = member_girder.isfg;
nmc_ = length(member_column.idme);
onfg_x = false(nmc_, 1);
onfg_y = false(nmc_, 1);
for ic = 1:nmc_
  in = col_in1(ic);
  is_conn = (gir_in1 == in | gir_in2 == in);
  is_fg = is_conn & gir_isfg;
  if any(is_fg)
    onfg_x(ic) = any(gir_isxdir(is_fg));
    onfg_y(ic) = any(gir_isydir(is_fg));
  end
end
com.member.column.onfg_x = onfg_x;
com.member.column.onfg_y = onfg_y;

%% 柱断面の検索
[com.section.column.idmec, com.section.column.idrepc, ...
  com.section.column.idmem, com.section.column.idrepm] = find_crep(com);

%% 梁断面の検索
[com.section.girder.idmeg, com.section.girder.idrepg, ...
  com.section.girder.idmem, com.section.girder.idrepm] = find_repg(com);

%% 名目梁
nominal_girder = com.nominal.girder;
com.num.nominal_girder = size(nominal_girder, 1);

%% 名目ブレース
[nominal_brace, idnominal_brace] = countup_nominal_brace(com);
com.nominal.brace = nominal_brace;
com.num.nominal_brace = size(nominal_brace,1);
com.member.brace.idnominal = idnominal_brace;

%% 一本部材
[nominal_property, idnominal_girder, idnominal_column, ...
  idnominal_brace, idnominal] = countup_nominal_property(com);
com.nominal.property = nominal_property;
com.num.nominal_member = size(nominal_property,1);
nominal_girder.idnominal = idnominal_girder;
com.nominal.girder = nominal_girder;
nominal_column.idnominal = idnominal_column;
com.nominal.column = nominal_column;
nominal_brace.idnominal = idnominal_brace;
com.nominal.brace = nominal_brace;
com.member.property.idnominal = idnominal;

%% 柱面番号の数え上げ
[idmeg2secl, idmeg2secr]  = countup_girder_to_column_face(com);
com.member.girder.idsec_facel = idmeg2secl;
com.member.girder.idsec_facer = idmeg2secr;

%% 梁面番号の数え上げ
[idmec2seg1x, idmec2seg1y, idmec2seg2x, idmec2seg2y, ...
  idmec2meg1x, idmec2meg1y, idmec2meg2x, idmec2meg2y] = ...
  countup_column_to_girder_face(com);
com.member.column.idsec_face1x = idmec2seg1x;
com.member.column.idsec_face1y = idmec2seg1y;
com.member.column.idsec_face2x = idmec2seg2x;
com.member.column.idsec_face2y = idmec2seg2y;
com.member.column.idmeg_face1x = idmec2meg1x;
com.member.column.idmeg_face1y = idmec2meg1y;
com.member.column.idmeg_face2x = idmec2meg2x;
com.member.column.idmeg_face2y = idmec2meg2y;

%% ブレース端点の柱・梁部材番号の数え上げ
[idmecb1, idmecb2, has_girderb1, has_girderb2, idmegb_selected1, ...
  idmegb_selected2] = countup_brace_to_column_girder(com);
com.member.brace.idmec1 = idmecb1;
com.member.brace.idmec2 = idmecb2;
com.member.brace.has_girder1 = has_girderb1;
com.member.brace.has_girder2 = has_girderb2;
com.member.brace.idmeg_selected1 = idmegb_selected1;
com.member.brace.idmeg_selected2 = idmegb_selected2;

%% 各位置の階高計算
column_floor_height = countup_column_floor_height(com);
com.member.column.floor_height = column_floor_height;

%% 柱梁耐力比の対象接合部（節点）
% 中間階の接合部数の数え上げ
% TODO 対象階の指定方法を見直しが必要
[com.cgsr.idnode, com.cgsr.idvofH, com.cgsr.idvofB, ...
  com.cgsr.idvoftw, com.cgsr.idvoftf, com.cgsr.idvofD, ...
  com.cgsr.idvoft, com.cgsr.istarget, com.cgsr.isxdir_member, ...
  com.cgsr.isydir_member] = countup_cgsr_node(com);
com.ncgsr = length(com.cgsr.idnode);

%% 方向別補剛点トポロジー
% 断面寸法に依存しない補剛点判定を前処理で確定する
com.column_bracing = countup_column_bracing_topology(com);
com.girder_bracing = countup_girder_bracing_topology(com);

%% 上下階関係
com.Dgap = table2struct(countup_column_gapjoint(com), 'ToScalar', true);

return
end

function  nbw = countup_band_width(com)
%countup_band_width - 部材両端の自由度番号からバンド幅を求める
%
%   nbw = countup_band_width(com) は、部材が接続する自由度番号の
%   最大差に1を加えた値を返す。
%
%   入力引数:
%     com - 部材の端節点番号と節点自由度番号を持つ共通データ
%
%   出力引数:
%     nbw - 剛性行列のバンド幅

% 共通配列
idm2n1 = com.member.property.idnode1;
idm2n2 = com.member.property.idnode2;
node = com.node;

% 各部材の自由度番号の最大距離がバンド幅
nd1 = min([node.dof(idm2n1,:) node.dof(idm2n2,:)],[],2);
nd2 = max([node.dof(idm2n1,:) node.dof(idm2n2,:)],[],2);
nbw = max(abs(nd2-nd1))+1;
return
end


function [idmec2seg1x, idmec2seg1y, idmec2seg2x, idmec2seg2y, ...
  idmec2meg1x, idmec2meg1y, idmec2meg2x, idmec2meg2y] = ...
  countup_column_to_girder_face(com)
%countup_column_to_girder_face - 柱端節点に接続する梁を方向別に集める
%
%   [idmec2seg1x, idmec2seg1y, idmec2seg2x, idmec2seg2y,
%   idmec2meg1x, idmec2meg1y, idmec2meg2x, idmec2meg2y] =
%   countup_column_to_girder_face(com) は、各柱端のX・Y方向に接続する
%   梁断面番号と梁部材番号を求める。接続のない欄は0とする。
%
%   入力引数:
%     com - 柱・梁の端節点番号と方向を持つ共通データ
%
%   出力引数:
%     idmec2seg1x - 柱脚X方向の統一断面番号
%     idmec2seg1y - 柱脚Y方向の統一断面番号
%     idmec2seg2x - 柱頭X方向の統一断面番号
%     idmec2seg2y - 柱頭Y方向の統一断面番号
%     idmec2meg1x - 柱脚X方向の梁部材番号
%     idmec2meg1y - 柱脚Y方向の梁部材番号
%     idmec2meg2x - 柱頭X方向の梁部材番号
%     idmec2meg2y - 柱頭Y方向の梁部材番号
%       各配列は [nmec×接続数]、接続数は全柱端共通で最低2列とする。

% 共通定数
nmec = com.nmec;
nmeg = com.nmeg;

% 共通配列
idmeg2n = [com.member.girder.idnode1 com.member.girder.idnode2];
idmec2n = [com.member.column.idnode1 com.member.column.idnode2];
idmeg2sec = com.section.girder.idsec(com.member.girder.idsecg);
idmeg2isxdir = com.member.girder.isxdir;
idmeg2isydir = com.member.girder.isydir;
iggg = 1:nmeg;
dirs = [PRM.X PRM.Y];
dir_flags = {idmeg2isxdir, idmeg2isydir};

% 最大接続梁本数を調査
max_n = 0;
for ic = 1:nmec
  for ilr = 1:2
    for k = 1:2
      is_target_dir = dir_flags{k};
      idmeg = iggg(any(idmeg2n==idmec2n(ic,ilr) & is_target_dir,2));
      max_n = max(max_n, length(idmeg));
    end
  end
end

% 最低2列は確保
max_n = max(max_n, 2);

% 計算の準備
idmec2seg1x = zeros(nmec, max_n);
idmec2seg1y = zeros(nmec, max_n);
idmec2seg2x = zeros(nmec, max_n);
idmec2seg2y = zeros(nmec, max_n);

idmec2meg1x = zeros(nmec, max_n);
idmec2meg1y = zeros(nmec, max_n);
idmec2meg2x = zeros(nmec, max_n);
idmec2meg2y = zeros(nmec, max_n);

% 関係する変数の数え上げ
for ic = 1:nmec
  for ilr = 1:2
    for k = 1:2
      idir = dirs(k);
      % 対象変数の特定
      is_target_dir = dir_flags{k};
      idmeg = iggg(any(idmeg2n==idmec2n(ic,ilr) & is_target_dir,2));

      % 節点の格納
      n = length(idmeg);
      iddd = zeros(1, max_n);
      if n > 0
        iddd(1:n) = idmeg2sec(idmeg);
      end
      switch ilr
        case 1
          switch idir
            case PRM.X
              if n > 0
                idmec2meg1x(ic,1:n) = idmeg(1:n);
              end
              idmec2seg1x(ic,:) = iddd;
            case PRM.Y
              if n > 0
                idmec2meg1y(ic,1:n) = idmeg(1:n);
              end
              idmec2seg1y(ic,:) = iddd;
          end
        case 2
          switch idir
            case PRM.X
              if n > 0
                idmec2meg2x(ic,1:n) = idmeg(1:n);
              end
              idmec2seg2x(ic,:) = iddd;
            case PRM.Y
              if n > 0
                idmec2meg2y(ic,1:n) = idmeg(1:n);
              end
              idmec2seg2y(ic,:) = iddd;
          end
      end
    end
  end
end

return
end


function [idsecc2mec, idsecc2crep, idsecc2mem, idsecc2repm] = ...
  find_crep(com)
%find_crep - 柱断面ごとの部材番号と代表部材番号を求める
%
%   [idsecc2mec, idsecc2crep, idsecc2mem, idsecc2repm] = find_crep(com)
%   は、柱断面を使う部材を集め、その最初の部材番号を代表とする。
%
%   入力引数:
%     com - 柱断面と部材の対応を持つ共通データ
%
%   出力引数:
%     idsecc2mec  - 断面ごとの柱部材番号 {nsecc×1}
%     idsecc2crep - 代表柱部材番号 [nsecc×1]（部材なしは0）
%     idsecc2mem  - 断面ごとの統一部材番号 {nsecc×1}
%     idsecc2repm - 代表統一部材番号 [nsecc×1]（部材なしは0）

% 共通定数
nmec = com.nmec;
nsecc = com.nsecc;
nme = com.nme;

% 共通配列
member_column = com.member.column;
member_property = com.member.property;

% 該当断面を持つ部材の数え上げ
idsecc2mec = cell(nsecc,1);
idsecc2crep = zeros(nsecc,1);
idsecc2mem = cell(nsecc,1);
idsecc2repm = zeros(nsecc,1);
iccc = 1:nmec;
immm = 1:nme;
for isecc=1:nsecc
  % 柱部材番号
  ic = iccc(member_column.idsecc==isecc);
  idsecc2mec{isecc} = ic;
  if (~isempty(ic)>0)
    idsecc2crep(isecc) = ic(1);
  end
  % 部材番号
  im = immm(member_property.idsecc==isecc);
  idsecc2mem{isecc} = im;
  if (~isempty(im)>0)
    idsecc2repm(isecc) = im(1);
  end
end

return
end


function [idseg2meg, idseg2repg, idseg2mem, idseg2repm] = find_repg(com)
%find_repg - 梁断面ごとの部材番号と代表部材番号を求める
%
%   [idseg2meg, idseg2repg, idseg2mem, idseg2repm] = find_repg(com)
%   は、梁断面を使う部材を集め、その最初の部材番号を代表とする。
%
%   入力引数:
%     com - 梁断面と部材の対応を持つ共通データ
%
%   出力引数:
%     idseg2meg  - 断面ごとの梁部材番号 {nsecg×1}
%     idseg2repg - 代表梁部材番号 [nsecg×1]（部材なしは0）
%     idseg2mem  - 断面ごとの統一部材番号 {nsecg×1}
%     idseg2repm - 代表統一部材番号 [nsecg×1]（部材なしは0）

% 共通定数
nmeg = com.nmeg;
nsecg = com.nsecg;
nme = com.nme;

% 共通配列
member_girder = com.member.girder;
member_property = com.member.property;

% 該当断面を持つ部材の数え上げ
idseg2meg = cell(nsecg,1);
idseg2repg = zeros(nsecg,1);
idseg2mem = cell(nsecg,1);
idseg2repm = zeros(nsecg,1);
iggg = 1:nmeg;
immm = 1:nme;
for isecg=1:nsecg
  % 梁部材番号
  ig = iggg(member_girder.idsecg==isecg);
  idseg2meg{isecg} = ig;
  if (~isempty(ig)>0)
    idseg2repg(isecg) = ig(1);
  end
  % 部材番号
  im = immm(member_property.idsecg==isecg);
  idseg2mem{isecg} = im;
  if (~isempty(im)>0)
    idseg2repm(isecg) = im(1);
  end
end
return
end
