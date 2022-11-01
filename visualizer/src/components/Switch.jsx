import * as React from 'react';
import { styled } from '@mui/material/styles';
import FormGroup from '@mui/material/FormGroup';
import FormControlLabel from '@mui/material/FormControlLabel';
import Switch from '@mui/material/Switch';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

const MaterialUISwitch = styled(Switch)(({ theme }) => ({
	width: 62,
	height: 34,
	padding: 7,
	'& .MuiSwitch-switchBase': {
		margin: 1,
		padding: 0,
		transform: 'translateX(6px)',
		'&.Mui-checked': {
			color: '#fff',
			transform: 'translateX(22px)',
			'& .MuiSwitch-thumb:before': {
				backgroundImage: `url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" height="20" width="20" viewBox="0 0 20 20"><g><rect fill="none" height="24" width="24"/></g><g><g><rect fill="%23FFF" height="11" width="4" x="4" y="9"/><rect fill="%23FFF" height="7" width="4" x="16" y="13"/><rect fill="%23FFF" height="16" width="4" x="10" y="4"/></g></g></svg>')`,
			},
			'& + .MuiSwitch-track': {
				opacity: 1,
				backgroundColor: "slategrey",
			},
		},
	},
	'& .MuiSwitch-thumb': {
		backgroundColor: 'slategrey',
		width: 32,
		height: 32,
		'&:before': {
			content: "''",
			position: 'absolute',
			width: '100%',
			height: '100%',
			left: 0,
			top: 0,
			backgroundRepeat: 'no-repeat',
			backgroundPosition: 'center',
			backgroundImage: `url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" height="20" width="20" viewBox="0 0 20 20"><path d="M0 0h24v24H0z" fill="none"/><path fill="%23FFF" d="M3.5 18.49l6-6.01 4 4L22 6.92l-1.41-1.41-7.09 7.97-4-4L2 16.99z"/></svg>')`,
		},
	},
	'& .MuiSwitch-track': {
		opacity: 1,
		backgroundColor: theme.palette.mode === 'dark' ? '#8796A5' : '#aab4be',
		borderRadius: 20 / 2,
	},
}));


export default function CustomSwitch(props) {
	return (
		<FormGroup>
			<FormControlLabel
				sx={{
					color: "slategrey"
				}}
				control={<MaterialUISwitch sx={{ m: 1 }} defaultChecked value={props.value} onChange={props.onChange} />}
				label="Graph Style"
			/>
		</FormGroup>
	);
}
