import { useState } from 'react'
import './App.css'
import {
	Chart as ChartJS,
	CategoryScale,
	LinearScale,
	BarElement,
	Title,
	Tooltip,
	Legend,
	PointElement,
	LineElement,
	Filler
} from 'chart.js';
import { Bar } from 'react-chartjs-2';
import brnkl from "./data/brnkl-minified.json"
import combined from "./data/combined-minified.json"

import DeploymentFrequency from "./charts/deploymentFrequency";
import LeadTimeForChanges from "./charts/leadTimeForChanges";
import MeanTimeToRecover from "./charts/meanTimeToRecover";
import ChangeFailureRate from "./charts/changeFailureRate";
import {DAY, WEEK, MONTH, MONTH4, MONTH6, YEAR, getScaleLabel} from "./utils";
import Slider from "@mui/material/Slider";
import CustomSwitch from "./components/Switch";
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';

ChartJS.register(
	CategoryScale,
	LinearScale,
	BarElement,
	Title,
	Tooltip,
	Legend,
	PointElement,
	LineElement,
	Filler
);

combined.results = combined.results.filter(r => r.repo !== "kubernetes/kubernetes")
const dataset = combined;

function App() {

	const [scale, setScale] = useState(2);
	const [metric, setMetric] = useState(0);
	const [barChart, setBarChart] = useState(true);

	return (
		<div>
			<div style={{
				position: "absolute",
				width: "90vw",
				left: "5vw",
				top: "2.5vh",
				overflow: "visible",
				display: "flex",
				alignItems: "center",
				justifyContent: "center"
			}}>
				<Tabs onChange={(e, val) => {
					setMetric(val);
				}} value={metric} >
					<Tab label="DeploymentFrequency" value={0} />
					<Tab label="Lead Time For Changes" value={1} />
					<Tab label="Mean Time To Recover" value={2} />
					<Tab label="Change Failure Rate" value={3} />
				</Tabs>

			</div>

			<Slider
				sx={{
					position: "absolute",
					width: "40vw",
					left: "5vw",
					top: "10vh",
					overflow: "visible"
				}}
				aria-label="Custom marks"
				value={scale}
				onChange={e => {
					setScale(e.target.value);
				}}
				step={null}
				valueLabelFormat={val => {
					return getScaleLabel([DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1][val])
				}}
				min={1}
				max={6}
				valueLabelDisplay="auto"
				marks={[
					{value: 0, label: "Day"},
					{value: 1, label: "Week"},
					{value: 2, label: "Month"},
					{value: 3, label: "Four Months"},
					{value: 4, label: "Six Months"},
					{value: 5, label: "Year"},
					{value: 6, label: "Total"}
				]}
			/>
			<div style={{
				position: "absolute",
				width: "40vw",
				right: "5vw",
				top: "10vh",
				overflow: "visible",
				display: "flex",
				alignItems: "center",
				justifyContent: "center"
			}}>
				<CustomSwitch value={barChart} onChange={(e) => setBarChart(e.target.checked)} />
			</div>

			<div id="chart">{
				metric === 0 ? (
					<DeploymentFrequency data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1][scale]} />
				) : (metric === 1 ? (
					<LeadTimeForChanges data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1][scale]} />
				) : (metric === 2 ? (
					<MeanTimeToRecover data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1][scale]} />
				) : (
					<ChangeFailureRate data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1][scale]} />
				)))
			}</div>
		</div>
	)
}

export default App
