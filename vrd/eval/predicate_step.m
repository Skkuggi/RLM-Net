clc
clear all
DataPath = pwd;
fsep = filesep;
pos_v = strfind(DataPath,fsep);
DataPath = DataPath(1:pos_v(end));
datapath = 'outputs/output_predicate_recognition_stage/inference/vrd_val_3/'
lognum=65000;
UnionCNN=cell(1,1000);
for ii =1:1000
      a=cell2mat(struct2cell(load(strcat(DataPath,datapath,'extraction/predicate_eval/',num2str(lognum,'%07d'),'/',num2str(ii-1),'.mat'))));
    UnionCNN{ii}=a;
end
%% data loading
addpath('evaluation');
load('data/objectListN.mat'); 
%% We assume we have ground truth object detection
% we will change "predicate" in rlp_labels_ours use our prediction
fprintf('\n');
fprintf('#######  Predicate computing Begins  ####### \n');
for knum=[1,70]
k=knum;
load('evaluation/gt.mat');
rlp_labels_ours = gt_tuple_label; 
sub_bboxes_ours = gt_sub_bboxes;
obj_bboxes_ours = gt_obj_bboxes;
rlp_labels = gt_tuple_label; 
sub_bboxes = gt_sub_bboxes;
obj_bboxes = gt_obj_bboxes;
for ii = 1:1000
    rlp_labels{ii}=kron(rlp_labels_ours{ii},ones(k,1));
    sub_bboxes{ii}=kron(sub_bboxes_ours{ii},ones(k,1));
    obj_bboxes{ii}=kron(obj_bboxes_ours{ii},ones(k,1));
end

%% 
testNum = 1000;
for ii = 1 : testNum
    
%     if mod(ii, 100) == 0
%         fprintf([num2str(ii), 'th image is tested! \n']);
%     end
    
    len = size(gt_tuple_label{ii},1);
    if len ~= 0
        rlp_confs_ours{ii} = zeros(len, 1); 
        rlp_confs{ii} = zeros(k*len, 1);
    else
        rlp_confs_ours{ii} = []; 
        rlp_confs{ii} = []; 
    end
  
    for jj = 1 : len
        % vision modual
        visualModual = UnionCNN{ii}(jj,:) ;
        % score vector over relationship
        rlpScore = visualModual;
                    
        [m_score, m_preidcate]  = sort(rlpScore,'descend'); 
        m_preidcate = m_preidcate(1,1:k);
        m_score = m_score(1,1:k);
        m_preidcate=reshape(m_preidcate,k,1);
        m_score=reshape(m_score,k,1);
        rlp_labels{ii}(k*jj-k+1:k*jj,2) = m_preidcate(:,1);            
        rlp_confs{ii}(k*jj-k+1:k*jj) = m_score;   
    end
 
end

%% sort by confident score

for ii = 1 : length(rlp_confs_ours)
    [Confs, ind] = sort(rlp_confs{ii}, 'descend');
    rlp_confs{ii} = Confs;
    rlp_labels{ii} = rlp_labels{ii}(ind,:);
    sub_bboxes{ii} = sub_bboxes{ii}(ind,:);
    obj_bboxes{ii} = obj_bboxes{ii}(ind,:);
end
%% computing Predicate Det. accuracy
fprintf('\n');
fprintf('#######  Top recall results  ####### \n');
recall100R = top_recall_Relationship(100, rlp_confs, rlp_labels, sub_bboxes, obj_bboxes);
recall50R = top_recall_Relationship(50, rlp_confs, rlp_labels, sub_bboxes, obj_bboxes);
fprintf('Predicate Det. R@100,k=%d: %0.2f \n',knum, 100*recall100R);
fprintf('Predicate Det. R@50,k=%d: %0.2f \n',knum, 100*recall50R);

fprintf('\n');
fprintf('#######  Zero-shot results  ####### \n');
zeroShot100R = zeroShot_top_recall_Relationship(100, rlp_confs, rlp_labels, sub_bboxes, obj_bboxes);
zeroShot50R = zeroShot_top_recall_Relationship(50, rlp_confs, rlp_labels, sub_bboxes, obj_bboxes);
fprintf('zero-shot Predicate Det. R@100,k=%d: %0.2f \n',knum, 100*zeroShot100R);
fprintf('zero-shot Predicate Det. R@50,k=%d: %0.2f \n',knum, 100*zeroShot50R);
end