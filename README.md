# DORA

```sh
#Build dataset
./gh_get_starred_repos.sh > repos.dataset5.txt ; cat repos.dataset5.txt | ./build_dataset.sh > dataset5.txt
node build_config.js dataset5.txt  > paper5.json

#Start workers
node initialize_compute_instances.js paper5.json
ssh -i ~/.ssh/DORA-scheduler_keyPair.pem ubuntu@35.86.246.218 "~/dora/authenticate_compute_instances.sh dora"
ssh -i ~/.ssh/DORA-scheduler_keyPair.pem ubuntu@35.86.246.218 "~/dora/start_compute_instances.sh 'dora' 'ubuntu' '35.86.246.218' '~/.ssh/DORA-scheduler_keyPair.pem'"

#Retrieve results
node print_worker_status.js paper5.json > stdout5.txt
node retrieve_results.js paper5.json ; rm -rf results5/paper5-results.json ; node result_combiner.js results5/* results5/paper5-results.json ; node minimize.js results5/paper5-results.json visualizer/src/data/paper5-minified.json ; node stats.js visualizer/src/data/paper5-minified.json > stats.csv
```
