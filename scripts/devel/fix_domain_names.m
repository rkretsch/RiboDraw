function fix_domain_names()
% used during development but probably could be removed from the repo.
tags = get_tags( 'Selection_Domain' )
for i = 1:length( tags )
    domain = getappdata(gca, tags{i} )
    if ~isfield( domain, 'name' )
        domain.name = strrep( strrep( domain.selection_tag, 'Selection_','' ), '_' ,' ' );
        setappdata( gca, domain.selection_tag, domain );
    end
end
