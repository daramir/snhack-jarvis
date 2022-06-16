import { ChakraProvider } from '@chakra-ui/react'


function MyApp({ Component, pageProps }) {
  return (
    <ChakraProvider resetCSS>
      <style> @import url('https://fonts.googleapis.com/css2?family=My+Soul&display=swap'); </style>
      <Component style="font-family: 'My Soul', cursive;" {...pageProps} />
    </ChakraProvider>
  )
}

export default MyApp
