function [ res_tags, obj_name ] = get_res( selection )
% [ res_tags, obj_name ] = get_res( selection )
%  get tags for residues sorted by residue and chain.
%
% INPUT
% selection = string with name of selection (domain,residue,whatever)
%
% OUTPUTS
% res_tags  = all residues associated with selection, SORTED by res chain!
% obj_name  = object name with that selection 
%
% (C) R. Das, Stanford University

res_tags = {};
obj_name = '';

if ~exist( 'selection','var') selection ='all'; end;
if iscell( selection )
    for i = 1:length( selection )
        [ res_tags_i, obj_name ] = get_res( selection{i} );
        res_tags = [res_tags, res_tags_i ]; 
    end
    return;
end
if isnumeric( selection ); selection = num2str( selection ); end;

if strcmp( selection, 'all' )
    res_tags = get_tags( 'Residue_' );
else
    [resnum,chains,segid,ok] = get_resnum_from_tag( selection );
    if ok 
        for i = 1:length( resnum )
            res_tag = sanitize_tag(sprintf( 'Residue_%s%s%d', chains(i), segid{i}, resnum(i) ));
            if isappdata( gca, res_tag )
                res_tags = [res_tags, res_tag ];
            end
        end
    elseif ~isempty(str2num(selection)) % just a number
        resnum = str2num(selection);
        res_tags = {};
        tags = get_tags( 'Residue_' );
        for i = 1:length( tags )
            residue = getappdata( gca, tags{i} );
            if (residue.resnum == resnum)
                res_tags = [ res_tags, tags{i} ];
            end
        end
    else
        vals = getappdata( gca );
        objnames = fields( vals );
        if any( strcmp( objnames, selection ) )
            obj = getappdata( gca, selection );
            if isfield( obj, 'associated_residues' )
                res_tags = obj.associated_residues;
            else
                res_tags = { selection };
            end
            obj_name = selection;
        else
            for n = 1:length( objnames )
                obj = getappdata( gca, objnames{n} );
                if isfield( obj, 'associated_residues' ) & ...
                    isfield( obj, 'name' ) & ...
                    strcmp( obj.name, selection )
                    res_tags = obj.associated_residues;
                    obj_name = objnames{n};
                    break;
                end
                if isfield( obj, 'name' ) & ...
                       strcmp( obj.name, selection )
                    res_tags = { objnames{n} };
                    obj_name = objnames{n};
                    break;
                end
            end
        end 
    end
end

if length( res_tags ) == 0
    obj_name = '';
    fprintf( 'Could not find residues for selection %s\n', selection );
    return;
end

reschain = {};
% now sort based on order
for i = 1:length( res_tags )
    residue = getappdata( gca, res_tags{i} );
    reschain{i} = sprintf( '%2s:%s:%09d', residue.chain,residue.segid,residue.resnum );
end
[~,idx] = sort( reschain );
res_tags = res_tags( idx );
