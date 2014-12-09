use strictures;

package math_3d;

use Moo::Role;

use PDL;    # pdl tan

use Inline 'Pdlpp' => <<'END';
pp_def(
    'rotate',
    Pars => 'vec(n); angle(); axis(n)',
    Code => q{
        double PI = 3.141592653589793;
        double SinHalfAngle = sin( $angle() / 2.0 / 180.0 * PI );
        double CH = cos( $angle() / 2.0 / 180.0 * PI );

        // rotation quaternion
        double Rx = $axis(n=>0) * SinHalfAngle;
        double Ry = $axis(n=>1) * SinHalfAngle;
        double Rz = $axis(n=>2) * SinHalfAngle;

        double Vx = $vec(n=>0);
        double Vy = $vec(n=>1);
        double Vz = $vec(n=>2);

        // first step
        double x1 =   ( CH * Vx ) + ( Ry * Vz ) - ( Rz * Vy );
        double y1 =   ( CH * Vy ) + ( Rz * Vx ) - ( Rx * Vz );
        double z1 =   ( CH * Vz ) + ( Rx * Vy ) - ( Ry * Vx );
        double w1 = - ( Rx * Vx ) - ( Ry * Vy ) - ( Rz * Vz );

        // conjugated quaternion
        double Qx = Rx * -1;
        double Qy = Ry * -1;
        double Qz = Rz * -1;

        // second step
        $vec(n=>0) = ( x1 * CH ) + ( w1 * Qx ) + ( y1 * Qz ) - ( z1 * Qy );
        $vec(n=>1) = ( y1 * CH ) + ( w1 * Qy ) + ( z1 * Qx ) - ( x1 * Qz );
        $vec(n=>2) = ( z1 * CH ) + ( w1 * Qz ) + ( x1 * Qy ) - ( y1 * Qx );
    },
);
END

use constant PI => 3.141592653589793;

sub ToRadian { shift() / 180 * PI }

sub ToDegree { shift() * 180 / PI }

sub InitScaleTransform {
    my ( $self, $scale ) = @_;
    my $m = pdl(    #
        [ $scale->[0], 0,           0,           0 ],
        [ 0,           $scale->[1], 0,           0 ],
        [ 0,           0,           $scale->[2], 0 ],
        [ 0,           0,           0,           1 ],
    )->float;
    return $m;
}

sub InitRotateTransform {
    my ( $self, $rotate ) = @_;

    my $x = ToRadian( $rotate->[0] );
    my $y = ToRadian( $rotate->[1] );
    my $z = ToRadian( $rotate->[2] );

    $_ = $x;
    my $rx = pdl(    #
        [ 1, 0,      0,       0 ],
        [ 0, cos $_, -sin $_, 0 ],
        [ 0, sin $_, cos $_,  0 ],
        [ 0, 0,      0,       1 ],
    )->float;

    $_ = $y;
    my $ry = pdl(    #
        [ cos $_, 0, -sin $_, 0 ],
        [ 0,      1, 0,       0 ],
        [ sin $_, 0, cos $_,  0 ],
        [ 0,      0, 0,       1 ],
    )->float;

    $_ = $z;
    my $rz = pdl(    #
        [ cos $_, -sin $_, 0, 0 ],
        [ sin $_, cos $_,  0, 0 ],
        [ 0,      0,       1, 0 ],
        [ 0,      0,       0, 1 ],
    )->float;

    my $m = $rz x $ry x $rx;

    return $m;
}

sub InitTranslationTransform {
    my ( $self, $WorldPos ) = @_;
    my $m = pdl(    #
        [ 1, 0, 0, $WorldPos->[0] ],
        [ 0, 1, 0, $WorldPos->[1] ],
        [ 0, 0, 1, $WorldPos->[2] ],
        [ 0, 0, 0, 1 ],
    )->float;
    return $m;
}

sub InitPerspectiveProj {
    my ( $self, $m_persProj ) = @_;

    my $ar         = $m_persProj->{Width} / $m_persProj->{Height};
    my $zNear      = $m_persProj->{zNear};
    my $zFar       = $m_persProj->{zFar};
    my $zRange     = $zNear - $zFar;
    my $tanHalfFOV = tan ToRadian( $m_persProj->{FOV} / 2 );

    my $m = pdl(    #
        [ 1 / ( $tanHalfFOV * $ar ), 0, 0, 0 ],
        [ 0, 1 / $tanHalfFOV, 0, 0 ],
        [ 0, 0, ( 0 - $zNear - $zFar ) / $zRange, 2 * $zFar * $zNear / $zRange ],
        [ 0, 0, 1, 0 ],
    )->float;

    return $m;
}

sub InitCameraTransform {
    my ( $self, $Target, $Up ) = @_;

    my $N = pdl( $Target )->norm;
    my $U = pdl( $Up )->norm;
    $U = crossp( $U, $N );
    my $V = crossp( $N, $U );

    my $m = pdl(    #
        [ list( $U ), 0 ],
        [ list( $V ), 0 ],
        [ list( $N ), 0 ],
        [ 0, 0, 0, 1 ],
    )->float;

    return $m;
}

1;
