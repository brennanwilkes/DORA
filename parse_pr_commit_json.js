try{
	const json = JSON.parse(require("fs").readFileSync(0, "utf-8"))
	if(process.argv[2] === "1"){
		console.log(json[0]?.sha)
	}
	else if(process.argv[2] === "2"){
		console.log(json.merge_commit_sha)
	}
	else if(process.argv[2] === "3"){
		console.log(`${json?.rate?.remaining},${json?.rate?.reset}`);
	}
	else if(process.argv[2] === "4"){
		console.log((json.commits ?? []).map(c => `${c.sha} ${new Date(c.commit?.author?.date).getTime() / 1000}`).join("\n"))
	}
	else if(process.argv[2] === "5"){
		// console.log(json.parents.map(parent => parent.sha).join("\n"));
		if(json?.parents && json.parents.length > 0){
			console.log(json.parents[0].sha);
		}
	}
	else if(process.argv[2] === "6"){
		if(json.files && json.files.length > 0){
			console.log((json.files ?? []).map(f => f.patch).join("\n"));
		}
		else{
			console.log(Date.now());
		}
	}
	else if(process.argv[2] === "7"){
		if(json.created_at){
			console.log(new Date(json.created_at).getTime() / 1000)
		}
	}
	else if(process.argv[2] === "8"){
		// if(json.files && json.files.length > 0){
		// 	console.log((json.files ?? []).map(f => f.patch).join("\n"));
		// }
		if(json.length){
			console.log(json.map(e => e.commit_id).filter(id => !!id).join("\n"))
		}
	}
	else{
		// This is 0
		console.log(new Date(json.merged_at).getTime() / 1000)
	}
} catch (e) {}
