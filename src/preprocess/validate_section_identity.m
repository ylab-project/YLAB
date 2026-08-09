function validate_section_identity(section_table, section_kind)
%validate_section_identity - 断面符号と階・層の重複を検証する
%
%   validate_section_identity(section_table, section_kind) は、
%   full_nameと階・層に対応するidstoryの組が一意であることを確認する。
%
%   入力引数:
%     section_table - full_nameとidstoryを持つ断面テーブル
%     section_kind  - エラー表示用の断面種別

% (full_name, idstory)を一意キーとして重複行を検出する
identity_key = section_table(:, {'full_name', 'idstory'});
[~, idfirst] = unique(identity_key, 'stable');
idduplicate = setdiff(1:height(section_table), idfirst);
if ~isempty(idduplicate)
  idup = idduplicate(1);
  error('YLAB:Input:DuplicateSection', ...
    '%s%sが同じ層に複数定義されています（層番号: %g）', ...
    section_kind, section_table.full_name{idup}, ...
    section_table.idstory(idup));
end

return
end
