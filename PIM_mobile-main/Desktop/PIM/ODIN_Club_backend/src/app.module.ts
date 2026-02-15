import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthModule } from './auth/auth.module';
import { UserModule } from './user/user.module';
import { EmailModule } from './email/email.module';
import { PlayersModule } from './players/players.module';
import { CoachesModule } from './coaches/coaches.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGODB_URI') || 'mongodb://localhost:27017/odin_club',
      }),
      inject: [ConfigService],
    }),
    AuthModule,
    UserModule,
    EmailModule,
    PlayersModule,
    CoachesModule,
  ],
})
export class AppModule {}
