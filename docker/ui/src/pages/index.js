import React from 'react';
import Header from '../components/header/Header';
import UserDomains from '../components/domain/UserDomains';
import styled from '@emotion/styled';
import Head from 'next/head';

import Search from '../components/search/Search';
import Error from './_error';
import { connect } from 'react-redux';
import { getHeaderDetails } from '../redux/thunks/domains';
import createCache from '@emotion/cache';
import { CacheProvider } from '@emotion/react';
import { selectIsLoading } from '../redux/selectors/loading';

const HomeContainerDiv = styled.div`
    flex: 1 1;
`;

const HomeContentDiv = styled.div`
    align-items: center;
    height: 100%;
    justify-content: flex-start;
    width: 100%;
    display: flex;
    flex-direction: column;
`;

const Logo = ({ className }) => (
    <img src='/static/athenz-logo.png' className={className} />
);

const LogoStyled = styled(Logo)`
    height: 100px;
    width: 100px;
`;

const MainLogoDiv = styled.div`
    padding-top: 20px;
`;

const DetailsDiv = styled.div`
    align-items: flex-start;
    line-height: 1.3;
    padding: 20px 0;
    text-align: center;
    width: 650px;
`;

const SearchContainerDiv = styled.div`
    padding: 20px 0 0 0;
    width: 600px;
`;

const AppContainerDiv = styled.div`
    align-items: stretch;
    flex-flow: row nowrap;
    height: 100%;
    display: flex;
    justify-content: flex-start;
`;

const MainContentDiv = styled.div`
    flex: 1 1 calc(100vh - 60px);
    overflow: hidden;
    font: 300 14px HelveticaNeue-Reg, Helvetica, Arial, sans-serif;
`;

const StyledAnchor = styled.a`
    color: #3570f4;
    text-decoration: none;
    cursor: pointer;
`;

export async function getServerSideProps(context) {
    let reload = false;
    let error = null;
    return {
        props: {
            reload,
            error,
            userName: context.req.session.shortId,
            nonce: context.req.headers.rid,
        },
    };
}

class PageHome extends React.Component {
    constructor(props) {
        super(props);
        this.cache = createCache({
            key: 'athenz',
            nonce: this.props.nonce,
        });
    }

    componentDidMount() {
        this.props.getHeaderDetails();
    }

    render() {
        if (this.props.reload) {
            window.location.reload();
            return <div />;
        }
        if (this.props.error) {
            return <Error err={this.props.error} />;
        }
        return this.props.isLoading.length ? (
            <h1>Is loading...</h1>
        ) : (
            <CacheProvider value={this.cache}>
                <div data-testid='home'>
                    <Head>
                        <title>Athenz</title>
                    </Head>
                    <Header showSearch={false} />
                    <MainContentDiv>
                        <AppContainerDiv>
                            <HomeContainerDiv>
                                <HomeContentDiv>
                                    <MainLogoDiv>
                                        <LogoStyled />
                                    </MainLogoDiv>
                                    <DetailsDiv>
                                        <span>
                                            Athenz is an open source platform
                                            which provides secure identity in
                                            the form of X.509 certificate to
                                            every workload for service
                                            authentication (mutual TLS
                                            authentication) and provides
                                            fine-grained Role Based Access
                                            Control (RBAC) for authorization.
                                        </span>
                                        <StyledAnchor
                                            rel='noopener'
                                            target='_blank'
                                            href='https://athenz.github.io/athenz/'
                                        >
                                            Learn more
                                        </StyledAnchor>
                                    </DetailsDiv>
                                    <SearchContainerDiv>
                                        <Search />
                                    </SearchContainerDiv>
                                </HomeContentDiv>
                            </HomeContainerDiv>
                            <UserDomains />
                        </AppContainerDiv>
                    </MainContentDiv>
                </div>
            </CacheProvider>
        );
    }
}

const mapStateToProps = (state, props) => ({
    ...props,
    isLoading: selectIsLoading(state),
});
const mapDispatchToProps = (dispatch) => ({
    getHeaderDetails: () => dispatch(getHeaderDetails()),
});

export default connect(mapStateToProps, mapDispatchToProps)(PageHome);
