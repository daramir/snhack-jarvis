import {
    Avatar,
    Badge,
    Box,
    Checkbox,
    HStack,
    Icon,
    IconButton,
    Table,
    Tbody,
    Td,
    Text,
    Th,
    Thead,
    Tr,
} from '@chakra-ui/react'
import * as React from 'react'
import { FiEdit2, FiTrash2 } from 'react-icons/fi'
import { IoArrowDown } from 'react-icons/io5'
import { RepeatClockIcon } from '@chakra-ui/icons'

const renderAddress = (address) => {
    return address.substring(0, 5) + "..." + address.substring(address.length - 4, address.length);
  }

export const MemberTable = (props) => (
    <Table {...props}>
        <Thead>
            <Tr>
                <Th>
                    <HStack spacing="3">
                        <HStack spacing="1">
                            <Text>Address</Text>
                            <Icon as={IoArrowDown} color="muted" boxSize="4" />
                        </HStack>
                    </HStack>
                </Th>
                <Th>USDC</Th>
                <Th>aUSDC</Th>
                <Th>Starknet Balance</Th>
                <Th></Th>
            </Tr>
        </Thead>
        <Tbody>
            {members.map((member) => (
                <Tr key={member.id}>
                    <Td>
                        <HStack spacing="3">
                            <Box>
                                <Text fontWeight="medium">{props.address}</Text>
                            </Box>
                        </HStack>
                    </Td>
                    <Td>
                        <Text color="muted">{props.deposited}</Text>
                    </Td>
                    <Td>
                        <Text color="muted">{props.earned}</Text>
                    </Td>
                    <Td>
                        <Text color="muted">{props.status}</Text>
                    </Td>
                </Tr>
            ))}
        </Tbody>
    </Table>
)

export const members = [
    {
        id: '1',
        name: '0x5B1Fd9f720C24f849cE344277862A80C8A874DBc',
        deposited: '100',
        status: 'pending',
        earned: '20',
    }
]