# DORA

```sh
#Build dataset
./gh_get_starred_repos.sh > repos.dataset4.txt ; cat repos.dataset4.txt | ./build_dataset.sh > dataset4.txt
node build_config.js dataset4.txt  > paper4.json

#Start workers
node initialize_compute_instances.js paper4.json
ssh -i ~/.ssh/DORA-scheduler_keyPair.pem ubuntu@35.86.246.218 "~/dora/authenticate_compute_instances.sh dora"
ssh -i ~/.ssh/DORA-scheduler_keyPair.pem ubuntu@35.86.246.218 "~/dora/start_compute_instances.sh 'dora' 'ubuntu' '35.86.246.218' '~/.ssh/DORA-scheduler_keyPair.pem'"

#Retrieve results
node print_worker_status.js paper4.json > stdout4.txt
node retrieve_results.js paper4.json ; rm -rf results4/paper4-results.json ; node result_combiner.js results4/* results4/paper4-results.json ; node minimize.js results4/paper4-results.json visualizer/src/data/paper4-minified.json
```
