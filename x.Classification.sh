for subject in MS-02; do
  for session in ses-01; do
    for task in HAND; do
      parent_dir="/home/pyp7823/AIHMS/Results/derivatives"
      
      python repositories/dtm_tools/dtm_tools.py \
        "${subject}_${session}" \
        "${parent_dir}/${subject}/${session}/func/${task}/output.tedana_auto/desc-tedana_metrics.tsv" \
        "${parent_dir}/${subject}/${session}/func/${task}/manual_classification.tsv"

    done
  done
done

