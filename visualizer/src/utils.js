export const BASE_COLOURS = ["#fd7f6f", "#7eb0d5", "#b2e061", "#bd7ebe", "#ffb55a", "#ffee65", "#8bd3c7", "#beb9db", "#fdcce5"];
BASE_COLOURS[-1] = "#555";
BASE_COLOURS[-2] = "#BBB";
export const COLOURS = BASE_COLOURS;
const HEX = "0123456789ABCDEF";
for (let i = 0; i < 200; i++) {
	COLOURS.push(`#${HEX[Math.floor(Math.random() * 16)]}${HEX[Math.floor(Math.random() * 16)]}${HEX[Math.floor(Math.random() * 16)]}${HEX[Math.floor(Math.random() * 16)]}${HEX[Math.floor(Math.random() * 16)]}${HEX[Math.floor(Math.random() * 16)]}`);
}

export const COLOURS_SEMI_TRANS = COLOURS.map(c => `${c}30`);
COLOURS_SEMI_TRANS[-1] = "#55555530";
COLOURS_SEMI_TRANS[-2] = "#BBBBBB30";
export const MINUTE = 60 * 1000;
export const HOUR = MINUTE * 60;
export const DAY = HOUR * 24;
export const YEAR = DAY * 365;
export const WEEK = YEAR / 52;
export const MONTH =  YEAR / 12;
export const MONTH4 = YEAR / 3;
export const MONTH6 = YEAR / 2;

export const divideTimes = (start, end, scale) => {
	if(scale === -1){
		return [[-1],["Total"]]
	}
	if(scale === -2){
		const N = 20;
		return [[-2], Array.from("%".repeat(N)).map((s,i) => {
			if(i === 0) return "Project Inception";
			if(i === N - 1) return "Current Day";
			return "";
		})];
	}

	let labels = [];
	let dates = [];
	let d;
	for (let i = end.getTime() + 1; i > start.getTime(); i -= scale){
		dates = [new Date(i), ...dates];
		if(scale === YEAR){
			d = new Date(i).getYear() + 1900;
		}
		else if(scale < MONTH){
			d = new Date(i).toISOString().split("T")[0];
		}
		else{
			d = `${["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][new Date(i).getMonth()]} ${new Date(i).getYear() + 1900}`;
		}
		labels = [d, ...labels];
	}
	return [dates, labels];
}

export const makeOptions = (title, yLabel, debug) => ({
	responsive:true,
	maintainAspectRatio: false,
	plugins: {
		legend: {
			display: debug,
			position: 'top',
		},
		title: {
			display: true,
			text: title,
		},
	},
	scales: {
		y: {
			title: {
				display: true,
				text: yLabel
			}
		}
	},
})


export const removeLeadingZeros = (d, i, arr) => {
	if(d === 0){
		let hasLeading = false;
		let hasTrailing = false;
		for(let j = i; j >=0; j--){
			if(arr[j] !== 0){
				hasLeading = true;
			}
		}
		for(let j = i; j < arr.length; j++){
			if(arr[j] !== 0){
				hasTrailing = true;
			}
		}
		if(hasLeading && hasTrailing){
			return d;
		}
		return undefined;
	}
	return d;
}

export const getScaleLabel = (val) => {
	if(val === DAY) return "Day";
	if(val === WEEK) return "Week";
	if(val === MONTH) return "Month";
	if(val === MONTH4) return "Four Months";
	if(val === MONTH6) return "Six Months";
	if(val === YEAR) return "Year";
	if(val === -2) return "Project Lifecycle";
	return "Total";
}

export const getColourIndex = (data) => {
	if(data === undefined || data === "avg" || data === "Trendline" || data === "Average") return -2;
	if(data === "Ultra") return 3;
	if(data === "High") return 2;
	if(data === "Medium") return 1;
	if(data === "Low") return 0;
	return -1;
}
