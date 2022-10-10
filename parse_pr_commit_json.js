const json = JSON.parse(require("fs").readFileSync(0, "utf-8"))
if(process.argv[2] === "1"){
	console.log(json[0]?.sha)
}
else{
	console.log(new Date(json.merged_at).getTime() / 1000)
}
