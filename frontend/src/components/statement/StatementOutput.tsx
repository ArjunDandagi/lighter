import React from 'react';
import {SessionStatement} from '../../client/types';
import {TypedSyntaxHighlighter} from '../../utils/syntaxHighlighter';

const StatementOutput: React.FC<{output?: SessionStatement['output']}> = ({output}) => {
  if (output?.traceback) {
    return <TypedSyntaxHighlighter>{output.traceback}</TypedSyntaxHighlighter>;
  }

  if (!output?.data) {
    return null;
  }

  const text = String(Object.values(output.data)[0]);
  if (!text) {
    return null;
  }

  return <TypedSyntaxHighlighter>{text}</TypedSyntaxHighlighter>;
};

export default StatementOutput;
