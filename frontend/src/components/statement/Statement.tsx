import React, {useMemo} from 'react';
import {SessionStatement} from '../../client/types';
import {useSessionStatementCancel} from '../../hooks/session';
import {Box, Card, Flex, IconButton, Spinner, VStack} from '@chakra-ui/react';
import StatementOutput from './StatementOutput';
import {FaCheck, FaStop} from 'react-icons/fa';
import {RiErrorWarningFill} from 'react-icons/ri';
import {Prism as SyntaxHighlighter, SyntaxHighlighterProps} from 'react-syntax-highlighter';

const SyntaxHighlighterComponent = SyntaxHighlighter as React.ComponentType<SyntaxHighlighterProps>;

const Statement: React.FC<{sessionId: string; statement: SessionStatement}> = ({sessionId, statement}) => {
  const {mutate: cancel, isPending: isCanceling} = useSessionStatementCancel(sessionId, statement.id);

  const statusIcon = useMemo(() => {
    switch (statement.state) {
      case 'available':
        return <FaCheck color="green" />;
      case 'cancelled':
        return <FaStop />;
      case 'error':
        return <RiErrorWarningFill color="red" />;
      case 'waiting':
        return <Spinner />;
    }
  }, [statement.state]);

  return (
    <Card.Root>
      <Card.Body>
        <VStack align="stretch" gap={1}>
          <Flex gap={2}>
            <Box flex={1}>
              <SyntaxHighlighterComponent language="python">{statement.code}</SyntaxHighlighterComponent>
              <StatementOutput output={statement.output} />
            </Box>
            <Box>
              <VStack>
                {statusIcon}
                {statement.state !== 'cancelled' ? (
                  <IconButton variant="ghost" onClick={() => cancel()} loading={isCanceling} aria-label="Cancel">
                    <FaStop />
                  </IconButton>
                ) : null}
              </VStack>
            </Box>
          </Flex>
        </VStack>
      </Card.Body>
    </Card.Root>
  );
};

export default Statement;
