function [idnode, idvofH, idvofB, idvoftw, idvoftf, idvofD, ...
  idvoft, istarget] = countup_cgsr_node(com)
%countup_cgsr_node - 柱梁耐力比の対象節点と対象方向を数え上げる

% 共通定数
nme = com.nme;
nnode = com.nnode;
nstory = com.nstory;

% 共通配列
idm2n = [com.member.property.idnode1 com.member.property.idnode2];
idm2var = com.member.property.idvar;
idn2s = com.node.idstory;
mtype = com.member.property.type;
idmeg2m = com.member.girder.idme;
[isxdir_member, isydir_member] = expand_girder_direction_flags( ...
  nme, idmeg2m, com.member.girder.isxdir, com.member.girder.isydir);
is_both_pin_member = expand_both_pin_nominal_girder(com, nme);

% RC柱判定用
section_type = com.member.property.section_type;

% 対象節点の数え上げ
is_cgsr_node = false(nnode,1);
for istory=2:nstory-1
  is_cgsr_node(idn2s==istory) = true;
end
idnode = 1:nnode;
idnode = idnode(is_cgsr_node);
ncgsr = sum(is_cgsr_node);

% 計算の準備
immm = 1:nme;
istarget = false(ncgsr,2);
idvofH = cell(ncgsr,2);
idvofB = cell(ncgsr,2);
idvoftw = cell(ncgsr,2);
idvoftf = cell(ncgsr,2);
idvofD = cell(ncgsr,1);
idvoft = cell(ncgsr,1);

% 関係する変数の数え上げ
for icg = 1:ncgsr
  % 対象変数の特定
  in = idnode(icg);
  isconnected = any(idm2n==in,2);
  isxdir = isconnected & isxdir_member & mtype==PRM.GIRDER;
  isydir = isconnected & isydir_member & mtype==PRM.GIRDER;
  isxdir = isxdir & ~is_both_pin_member;
  isydir = isydir & ~is_both_pin_member;
  idmofxdir = immm(isxdir);
  idmofydir = immm(isydir);
  idmofc = immm(isconnected&mtype==PRM.COLUMN);

  % S材とRC材が混在する節点は除外
  idmall = immm(isconnected);  % 節点に接続する全部材
  if ~isempty(idmall)
    has_s_member = any(section_type(idmall) ~= PRM.RCRS);
    has_rc_member = any(section_type(idmall) == PRM.RCRS);
    if has_s_member && has_rc_member
      continue
    end
  end

  % 柱または有効な梁が取り付かない節点は除外
  % 柱1本（上柱なし等）の中間階節点はSS7と同様に検討対象とする
  nmofc = length(idmofc);
  if (isempty(idmofxdir)&&isempty(idmofydir)) || nmofc < 1
    continue
  end
  istarget(icg,:) = [~isempty(idmofxdir) ~isempty(idmofydir)];
  idvofH{icg,1} = unique(idm2var(idmofxdir,1));
  idvofH{icg,2} = unique(idm2var(idmofydir,1));
  idvofB{icg,1} = unique(idm2var(idmofxdir,2));
  idvofB{icg,2} = unique(idm2var(idmofydir,2));
  idvoftw{icg,1} = unique(idm2var(idmofxdir,3));
  idvoftw{icg,2} = unique(idm2var(idmofydir,3));
  idvoftf{icg,1} = unique(idm2var(idmofxdir,4));
  idvoftf{icg,2} = unique(idm2var(idmofydir,4));
  idvofD{icg} = unique(idm2var(idmofc,1));
  idvoft{icg} = unique(idm2var(idmofc,2));
end

% 結果の整理
iskeep = any(istarget,2);
idnode = idnode(iskeep);
idvofH = idvofH(iskeep,:);
idvofB = idvofB(iskeep,:);
idvoftw = idvoftw(iskeep,:);
idvoftf = idvoftf(iskeep,:);
idvofD = idvofD(iskeep,:);
idvoft = idvoft(iskeep,:);
istarget = istarget(iskeep,:);
return
end

%--------------------------------------------------------------------------
function is_both_pin_member = expand_both_pin_nominal_girder(com, nme)
%expand_both_pin_nominal_girder - 両端PINの名目梁を部材配列へ展開する

is_both_pin_member = false(nme,1);
if ~isfield(com, 'nominal') || ~isfield(com.nominal, 'girder')
  return
end

girder = com.member.girder;
if ~has_table_field(girder, 'idnominal')
  return
end

nominal_girder = com.nominal.girder;
idmeg = nominal_girder.idmeg;
nng = size(idmeg,1);
is_both_pin_nominal = false(nng,1);
for ing = 1:nng
  ids = nonzeros(idmeg(ing,:));
  if isempty(ids)
    continue
  end
  is_both_pin_nominal(ing) = girder.joint(ids(1),1) == PRM.PIN ...
    && girder.joint(ids(end),2) == PRM.PIN;
end

idg2ng = girder.idnominal(:,1);
isvalid = idg2ng > 0;
is_both_pin_member(girder.idme(isvalid)) = ...
  is_both_pin_nominal(idg2ng(isvalid));
return
end
