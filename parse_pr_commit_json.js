const json = JSON.parse(require("fs").readFileSync(0, "utf-8"))
if(process.argv[2] === "1"){
	console.log(json[0]?.sha)
}
else if(process.argv[2] === "2"){
	console.log(json.merge_commit_sha)
}
else if(process.argv[2] === "3"){
	console.log(`${json.rate.remaining},${json.rate.reset}`);
}
else if(process.argv[2] === "4"){
	console.log(json.commits.map(c => `${c.sha} ${new Date(c.commit.author.date).getTime() / 1000}`).join("\n"))
}
else{
	console.log(new Date(json.merged_at).getTime() / 1000)
}
