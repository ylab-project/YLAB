function [idnode, idvofH, idvofB, idvoftw, idvoftf, idvofD, idvoft] = ...
  countup_cgsr_node(com)
% 共通定数
nme = com.nme;
nnode = com.nnode;
nstory = com.nstory;

% 共通配列
idm2n = [com.member.property.idnode1 com.member.property.idnode2];
idm2var = com.member.property.idvar;
idn2s = com.node.idstory;
medir = com.member.property.idir;
mtype = com.member.property.type;
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
istarget = true(1,ncgsr);
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
  % 45度梁（PRM.XY）は両方向に含める
  idmofgx = immm(isconnected&(medir==PRM.X|medir==PRM.XY)&mtype==PRM.GIRDER);
  idmofgy = immm(isconnected&(medir==PRM.Y|medir==PRM.XY)&mtype==PRM.GIRDER);
  idmofc = immm(isconnected&mtype==PRM.COLUMN);
  
  % S材とRC材が混在する節点は除外
  idmall = immm(isconnected);  % 節点に接続する全部材
  if ~isempty(idmall)
    has_s_member = any(section_type(idmall) ~= PRM.RCRS);
    has_rc_member = any(section_type(idmall) == PRM.RCRS);
    if has_s_member && has_rc_member
      % S材とRC材が混在する場合は対象外
      istarget(icg) = false;
      continue
    end
  end

  % 柱または梁が取り付かない節点は除外
  nmofc = length(idmofc);
  if (isempty(idmofgx)&&isempty(idmofgy)) || nmofc < 2
    istarget(icg) = false;
    continue
  end
  idvofH{icg,1} = unique(idm2var(idmofgx,1));
  idvofH{icg,2} = unique(idm2var(idmofgy,1));
  idvofB{icg,1} = unique(idm2var(idmofgx,2));
  idvofB{icg,2} = unique(idm2var(idmofgy,2));
  idvoftw{icg,1} = unique(idm2var(idmofgx,3));
  idvoftw{icg,2} = unique(idm2var(idmofgy,3));
  idvoftf{icg,1} = unique(idm2var(idmofgx,4));
  idvoftf{icg,2} = unique(idm2var(idmofgy,4));
  idvofD{icg} = unique(idm2var(idmofc,1));
  idvoft{icg} = unique(idm2var(idmofc,2));
end

% 結果の整理
idnode = idnode(istarget);
idvofH = idvofH(istarget,:);
idvofB = idvofB(istarget,:);
idvoftw = idvoftw(istarget,:);
idvoftf = idvoftf(istarget,:);
idvofD = idvofD(istarget,:);
idvoft = idvoft(istarget,:);
end
