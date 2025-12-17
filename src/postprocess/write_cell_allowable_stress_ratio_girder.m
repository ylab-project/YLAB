function [head, body] = ...
  write_cell_allowable_stress_ratio_girder(com, result)

% 定数
nsg = com.nsecg;
nlc = com.nlc;
nstory = com.nstory;
nng = com.num.nominal_girder;
nmg = com.num.member.girder;
nwfs = sum(com.member.girder.section_type==PRM.WFS);

% 共通配列
girder = com.member.girder;
nominal_girder = com.nominal.girder;
secg = com.section.girder;
gstype = com.section.girder.type;
isjbs = com.exclusion.is_joint_bearing_strength;

% 梁許容応力度比（部材単位の各ケース最大値）
gri_all = result.gri;
grj_all = result.grj;
grc_all = result.grc;
gsi_all = result.gsi;
gsj_all = result.gsj;
jbsratio = result.jbsratio;

% --- ヘッダ ---
head = cell(3,11);
head(1,1:8) = {'層', '符号', 'M', '', '', 'Q'	, '', '保有耐力接合(仕口)'};
head(2,1:11) = {... 
  '', '', '左端', '中央', '右端', '左端', '右端', '左端', '', '右端', ''};
head(3,8:11) = {'M', 'Q', 'M', 'Q'};

% --- S梁断面算定表 ---
body = cell(0,size(head,2));
if nsg==0 || isempty(gri_all) || isempty(grj_all) ...
    || isempty(grc_all) || isempty(gsi_all) || isempty(gsj_all)
  return
end
gri = reshape(gri_all,[],nlc)+1;
grj = reshape(grj_all,[],nlc)+1;
grc = reshape(grc_all,[],nlc)+1;
gsi = reshape(gsi_all,[],nlc)+1;
gsj = reshape(gsj_all,[],nlc)+1;
grimax = max(gri,[],[2 3]);
grjmax = max(grj,[],[2 3]);
grcmax = max(grc,[],2);
gsimax = max(gsi,[],[2 3]);
gsjmax = max(gsj,[],[2 3]);
body = cell(nsg,11);
iggg = 1:nng;
% idnm2meg = nominal_girder.idmeg(:,1);
idnm2sg = girder.idsecg(nominal_girder.idmeg(:,1));
idmg2mwfs = zeros(nmg,1); 
idmg2mwfs(com.member.girder.section_type==PRM.WFS) = 1:nwfs;
irow = 0;
for i = 1:nstory
  ist = nstory-i+1;
  for isg = 1:nsg
    if secg.idstory(isg)~=ist
      continue
    end
    if gstype(isg)~=PRM.WFS
      continue
    end
    ing = iggg(idnm2sg==isg);

    % 除外
    if ~nominal_girder.is_allowable_stress(ing)
      continue
    end

    % 検定値
    irow = irow+1;
    gri_ = max(grimax(ing));
    grj_ = max(grjmax(ing));
    grc_ = max(grcmax(ing));
    gsi_ = max(gsimax(ing));
    gsj_ = max(gsjmax(ing));

    % 切り上げ
    gri_ = ceil(gri_*100)/100;
    grj_ = ceil(grj_*100)/100;
    grc_ = ceil(grc_*100)/100;
    gsi_ = ceil(gsi_*100)/100;
    gsj_ = ceil(gsj_*100)/100;

    % 保有耐力接合(仕口)
    if ~isempty(jbsratio)
      img = sort(nominal_girder.idmeg(ing,:));
      img = img(img>0);
      imwfs = idmg2mwfs(img);
      imwfs = imwfs(imwfs>0);
      jbsratio1 = jbsratio; jbsratio1(~isjbs(:,1)) = 0;
      jbsratio1 = max(jbsratio1(imwfs));
      jbsratio2 = jbsratio; jbsratio2(~isjbs(:,2)) = 0;
      jbsratio2 = max(jbsratio2(imwfs));
      jbsratio1 = ceil(jbsratio1*100)/100;
      jbsratio2 = ceil(jbsratio2*100)/100;
    end

    % 書き出し
    body{irow,1} = secg.story_name{isg};
    body{irow,2} = sprintf('%s', ...
      [secg.subindex{isg} secg.name{isg}]);
    body{irow,3} = sprintf('%.2f', gri_);
    body{irow,4} = sprintf('%.2f', grc_);
    body{irow,5} = sprintf('%.2f', grj_);
    body{irow,6} = sprintf('%.2f', gsi_);
    body{irow,7} = sprintf('%.2f', gsj_);

    % 保有耐力接合(仕口)
    if ~isempty(jbsratio)
      body{irow,8} = sprintf('%.2f', jbsratio1);
      body{irow,10} = sprintf('%.2f', jbsratio2);
    end
  end
end
return
end
