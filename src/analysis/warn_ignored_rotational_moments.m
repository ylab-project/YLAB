function warn_ignored_rotational_moments(ignored, node, ...
  idm2n1, idm2n2, loadcase_names)
%warn_ignored_rotational_moments - 無視したモーメントを警告する
%
%   warn_ignored_rotational_moments(ignored, node, idm2n1, ...
%     idm2n2, loadcase_names) は、ピン端固定端力と孤立回転自由度で
%   0にしたモーメントを、位置・方向・荷重ケース付きで警告する。
%
%   入力引数:
%     ignored       - 無視したモーメント（.member、.node）
%     node          - 節点情報
%     idm2n1        - 部材始端の節点番号 [nme x 1]
%     idm2n2        - 部材終端の節点番号 [nme x 1]
%     loadcase_names - 荷重ケース名 [nlc x 1]
%
%   出力引数:
%     なし

nme = size(ignored.member,1);
nlc = size(ignored.member,3);
force_columns = [5 11 6 12];
end_numbers = [1 2 1 2];
axis_names = {'局所Y', '局所Y', '局所Z', '局所Z'};
for ipair = 1:length(force_columns)
  force_column = force_columns(ipair);
  values = reshape(ignored.member(:,force_column,:),nme,nlc);
  target_members = find(any(abs(values) > PRM.TOL_IGNORED_MOMENT_NMM,2));
  for im = reshape(target_members,1,[])
    target_cases = find(abs(values(im,:)) > PRM.TOL_IGNORED_MOMENT_NMM);
    if end_numbers(ipair) == 1
      idnode = idm2n1(im);
      end_name = 'i端';
    else
      idnode = idm2n2(im);
      end_name = 'j端';
    end
    source = sprintf('ピン端固定端力（部材%d・%s）',im,end_name);
    case_text = char(strjoin(string(loadcase_names(target_cases)), ', '));
    max_value = max(abs(values(im,target_cases)));
    zname = node.zname{idnode};
    xname = node.xname{idnode};
    yname = node.yname{idnode};
    throw_warn('Input', 'RotationalMomentIgnored', source, ...
      zname, xname, yname, axis_names{ipair}, case_text, max_value);
  end
end

nnode = size(ignored.node,1);
nlc = size(ignored.node,3);
direction_names = {'MX', 'MY'};
for comp = 4:5
  values = reshape(ignored.node(:,comp,:),nnode,nlc);
  target_nodes = find(any(abs(values) > PRM.TOL_IGNORED_MOMENT_NMM,2));
  for idnode = reshape(target_nodes,1,[])
    target_cases = find(abs(values(idnode,:)) > ...
      PRM.TOL_IGNORED_MOMENT_NMM);
    case_text = char(strjoin(string(loadcase_names(target_cases)), ', '));
    max_value = max(abs(values(idnode,target_cases)));
    zname = node.zname{idnode};
    xname = node.xname{idnode};
    yname = node.yname{idnode};
    throw_warn('Input', 'RotationalMomentIgnored', ...
      '回転剛性のない自由度', zname, xname, yname, ...
      direction_names{comp - 3}, case_text, max_value);
  end
end

return
end
