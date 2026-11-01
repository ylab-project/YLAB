function warn_ignored_rotational_moments(ignored, node, loadcase_names)
%warn_ignored_rotational_moments - 無視したモーメントを警告する
%
%   warn_ignored_rotational_moments(ignored, node, loadcase_names) は、
%   回転剛性のない節点自由度で0にしたモーメントを、位置・方向・
%   荷重ケース付きで警告する。
%
%   入力引数:
%     ignored        - 無視した節点モーメント [nnode x 6 x nlc]
%     node           - 節点情報
%     loadcase_names - 荷重ケース名 [nlc x 1]
%
%   出力引数:
%     なし

nnode = size(ignored,1);
nlc = size(ignored,3);
direction_names = {'MX', 'MY'};
for comp = 4:5
  values = reshape(ignored(:,comp,:),nnode,nlc);
  target_nodes = find(any(abs(values) > PRM.TOL_IGNORED_MOMENT_NMM,2));
  for idnode = reshape(target_nodes,1,[])
    target_cases = find(abs(values(idnode,:)) > ...
      PRM.TOL_IGNORED_MOMENT_NMM);
    case_text = char(strjoin(string(loadcase_names(target_cases)), ', '));
    max_value = max(abs(values(idnode,target_cases)));
    zname = node.zname{idnode};
    xname = node.xname{idnode};
    yname = node.yname{idnode};
    throw_warn('Input', 'RotationalMomentIgnored', zname, xname, ...
      yname, direction_names{comp - 3}, case_text, max_value);
  end
end

return
end
