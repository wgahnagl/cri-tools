#!/bin/bash

# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Run critest with default dockershim.

set -o errexit
set -o nounset
set -o pipefail

arch=$(uname -m)

# Install nsenter
if [ "$arch" == x86_64 ]; then
	docker run --rm -v /usr/local/bin:/target jpetazzo/nsenter
else
	apt-get install util-linux
fi

# Start dockershim first
/usr/local/bin/kubelet --v=3 --logtostderr --experimental-dockershim &

# Wait a while for dockershim starting.
sleep 10

# Run e2e test cases
# Skip reopen container log test because docker doesn't support it.
# Skip runtime should support execSync with timeout because docker doesn't
# support it.
if [ "$arch" == x86_64 ]; then
	critest -ginkgo.skip="runtime should support reopening container log|runtime should support execSync with timeout" -parallel 8
else
	critest -ginkgo.skip="runtime should support reopening container log|runtime should support execSync with timeout|runtime should support SupplementalGroups" -parallel 8
fi

# Run benchmark test cases
critest -benchmark
