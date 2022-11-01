export const COLOURS = ["#fd7f6f", "#7eb0d5", "#b2e061", "#bd7ebe", "#ffb55a", "#ffee65", "#beb9db", "#fdcce5", "#8bd3c7"];
export const COLOURS_SEMI_TRANS = COLOURS.map(c => `${c}60`);
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

	let labels = [];
	let dates = [];
	let d;
	for (let i = start.getTime() + scale; i <= end.getTime(); i += scale){
		dates = [...dates, new Date(i)];
		if(scale === YEAR){
			d = new Date(i).getYear() + 1900;
		}
		else if(scale < MONTH){
			d = new Date(i).toISOString().split("T")[0];
		}
		else{
			d = `${["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][new Date(i).getMonth()]} ${new Date(i).getYear() + 1900}`;
		}
		labels = [...labels, d];
	}
	return [dates, labels];
}

export const makeOptions = (title, yLabel) => ({
	responsive:true,
	maintainAspectRatio: false,
	plugins: {
		legend: {
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
	}
})
