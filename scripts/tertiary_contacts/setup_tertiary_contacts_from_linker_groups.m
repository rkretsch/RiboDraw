function tertiary_contact_tags = setup_tertiary_contacts_from_linker_groups( linker_groups )
% setup_tertiary_contacts( linker_groups )
%
% Helper function for setting up tertiary contacts.
%
% INPUTS:
%  linker_groups = cell of cells of linker tags that were grouped. 
% 
%
% (C) R. Das, Stanford University 2017-2018

tertiary_contact_tags = {};
linker_types_for_tertiary_contacts = get_linker_types_for_tertiary_contacts();

% let's try to set up a tertiary contact
for i = 1:length( linker_groups )
    linker_group = linker_groups{i};

    % need to assign a pair of interdomain connection residues.
    [res_tags1, res_tags2 ] = get_res_tags( linker_group );
    main_linker = look_for_previous_tertiary_contact( res_tags1, res_tags2 );
    if isempty( main_linker ) main_linker = find_shortest_possible_linker( linker_group, linker_types_for_tertiary_contacts ); end;
            
    % get all residues involved in tertiary contact.
    residue1 = getappdata( gca, main_linker.residue1 );
    residue2 = getappdata( gca, main_linker.residue2 );
    res_tags1 = [main_linker.residue1, setdiff( unique( res_tags1 ), main_linker.residue1 ) ];
    res_tags2 = [main_linker.residue2, setdiff( unique( res_tags2 ), main_linker.residue2 ) ];
    tertiary_contact_tags{i} = setup_tertiary_contact( '', res_tags1, res_tags2, main_linker, 1, 1, linker_group );
end

hide_tertiary_noncanonical_pairs;
hide_ligand_linkers;
show_tertiary_contacts;
%move_stuff_to_back; % already done in show_tertiary_contacts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [res_tags1,res_tags2] = get_res_tags( linker_group );
res_tags1 = {};
res_tags2 = {};
for j = 1:length( linker_group )
    linker = linker_group{j};
    res_tags1 = [res_tags1, linker.residue1 ];
    res_tags2 = [res_tags2, linker.residue2 ];
end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main_linker = find_shortest_possible_linker( linker_group, linker_types );
linker_lengths = [];
for j = 1:length( linker_group )
    linker = linker_group{j};
    linker_length = 0;
    if isfield( linker, 'plot_pos' )
        for i = 1:size( linker.plot_pos, 1 )-1
            linker_length = linker_length + norm( linker.plot_pos( i, : ) - linker.plot_pos( i+1, : ) );
        end
    else
        res1 = getappdata( gca, linker.residue1 );
        res2 = getappdata( gca, linker.residue2 );
        linker_length = norm( res1.plot_pos - res2.plot_pos );
    end
    linker_lengths(j,:) = [find(strcmp(linker.type, linker_types)), linker_length];
end
[~, idx ] = sortrows( linker_lengths );
main_linker = linker_group{idx};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main_linker = look_for_previous_tertiary_contact( res_tags1, res_tags2 );
main_linker = [];
tags = get_tags( 'TertiaryContact' );
for i = 1:length( tags )
    tertiary_contact = getappdata( gca, tags{i} );
    if ( any(strcmp(tertiary_contact.associated_residues1{1},res_tags1 )) & ...
            any(strcmp(tertiary_contact.associated_residues2{1},res_tags2 )) )
        fprintf( 'Found template linker from tertiary contact %s\n',  tags{i} );
        main_linker = getappdata( gca, tertiary_contact.interdomain_linker );
        return;
    elseif ( any(strcmp(tertiary_contact.associated_residues2{1},res_tags1 )) & ...
            any(strcmp(tertiary_contact.associated_residues1{1},res_tags2 ))   )
        fprintf( 'Found template linker from tertiary contact %s\n',  tags{i} );
        main_linker = getappdata( gca, tertiary_contact.interdomain_linker );
        res1 = main_linker.residue1;
        res2 = main_linker.residue2;
        main_linker.residue1 = res2;
        main_linker.residue2 = res1;
        return;
    end
end
