import { getDefaultConfig } from '@rainbow-me/rainbowkit'
import { sepolia, bscTestnet, polygonMumbai } from 'wagmi/chains'

export const config = getDefaultConfig({
	appName: 'Charity DAO',
	projectId: import.meta.env.VITE_PROJECT_ID,
	chains: [sepolia, bscTestnet, polygonMumbai],
})
